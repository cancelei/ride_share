import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "mapContainer",
    "pickupInput",
    "pickupSuggestions",
    "pickupAddress",
    "pickupLat",
    "pickupLng",
    "dropoffInput",
    "dropoffSuggestions",
    "dropoffAddress",
    "dropoffLat",
    "dropoffLng",
    "locationStatus",
  ];

  static values = {
    pickupLat: Number,
    pickupLng: Number,
    dropoffLat: Number,
    dropoffLng: Number,
    debounce: { type: Number, default: 300 }, // 300ms debounce
  };

  connect() {
    if (this.hasMapContainerTarget) {
      this.initializeMap();
      this.listenForLocationChanges();
    } else {
      console.log("Map container target not found");
    }

    this.debouncedFetch = this.debounce(
      this.performFetch.bind(this),
      this.debounceValue
    );

    // Apply initial styling to the suggestions dropdowns
    this.applySuggestionsStyle(this.pickupSuggestionsTarget);
    this.applySuggestionsStyle(this.dropoffSuggestionsTarget);

    // Add input event listeners
    if (this.hasPickupInputTarget) {
      this.pickupInputTarget.addEventListener(
        "input",
        this.debounce(() => {
          this.fetchSuggestions({ target: this.pickupInputTarget });
        }, 300)
      );
    }

    if (this.hasDropoffInputTarget) {
      this.dropoffInputTarget.addEventListener(
        "input",
        this.debounce(() => {
          this.fetchSuggestions({ target: this.dropoffInputTarget });
        }, 300)
      );
    }

    // Try to get user's location on page load if permitted
    this.tryGetCurrentLocationOnLoad();
    this.addLocationListener();
    this.addInputListeners();
  }

  addInputListeners() {
    if (this.hasPickupInputTarget) {
      this.pickupInputTarget.addEventListener("focus", () => {
        this.pickupSuggestionsTarget.classList.add("show");
      });
      this.pickupInputTarget.addEventListener("blur", () => {
        setTimeout(
          () => this.pickupSuggestionsTarget.classList.remove("show"),
          200
        );
      });
    }

    if (this.hasDropoffInputTarget) {
      this.dropoffInputTarget.addEventListener("focus", () => {
        this.dropoffSuggestionsTarget.classList.add("show");
      });
      this.dropoffInputTarget.addEventListener("blur", () => {
        setTimeout(
          () => this.dropoffSuggestionsTarget.classList.remove("show"),
          200
        );
      });
    }
  }

  clearPickupLocation() {
    this.clearLocationFields("pickup");
  }

  clearDropoffLocation() {
    this.clearLocationFields("dropoff");
  }

  clearLocationFields(type) {
    if (type === "pickup") {
      if (this.hasPickupInputTarget) this.pickupInputTarget.value = "";
      if (this.hasPickupAddressTarget) this.pickupAddressTarget.value = "";
      if (this.hasPickupLatTarget) this.pickupLatTarget.value = "";
      if (this.hasPickupLngTarget) this.pickupLngTarget.value = "";
    } else if (type === "dropoff") {
      if (this.hasDropoffInputTarget) this.dropoffInputTarget.value = "";
      if (this.hasDropoffAddressTarget) this.dropoffAddressTarget.value = "";
      if (this.hasDropoffLatTarget) this.dropoffLatTarget.value = "";
      if (this.hasDropoffLngTarget) this.dropoffLngTarget.value = "";
    }

    // Notify any listeners that locations have been cleared
    this.notifyLocationChange();
    this.clearMarker(type);
  }

  addLocationListener() {
    window.addEventListener("pin-dropped", async (event) => {
      await this.pinDropped(event.detail);
    });
  }

  async pinDropped(detail) {
    const { lat: latitude, lng: longitude } = detail;
    let addressDetail = await this.reverseGeocode(latitude, longitude);
    console.log(addressDetail);
  }

  // Try to get the user's location on page load
  tryGetCurrentLocationOnLoad() {
    // Check if geolocation is supported by the browser
    if (
      navigator.geolocation &&
      localStorage.getItem("userAllowedGeolocation") === "true"
    ) {
      this.useCurrentLocation();
    }
  }

  // Use the browser's geolocation API to get the current position
  useCurrentLocation() {
    if (!navigator.geolocation) {
      this.showLocationStatus(
        "Geolocation is not supported by your browser",
        "error"
      );
      return;
    }

    this.showLocationStatus("Getting your location...", "info");

    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const { latitude, longitude } = position.coords;
        await this.reverseGeocode(latitude, longitude);

        // Trigger an event for the map controller to show the user's location
        window.dispatchEvent(new CustomEvent("use-current-location"));
      },
      (error) => {
        console.error("Error getting location:", error);
        let errorMsg = "Error getting your location.";

        switch (error.code) {
          case error.PERMISSION_DENIED:
            errorMsg =
              "Location access denied. Please enable location services.";
            break;
          case error.POSITION_UNAVAILABLE:
            errorMsg = "Location information is unavailable.";
            break;
          case error.TIMEOUT:
            errorMsg = "Location request timed out.";
            break;
        }

        this.showLocationStatus(errorMsg, "error");
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0,
      }
    );
  }

  // Reverse geocode coordinates to get address
  async reverseGeocode(lat, lng) {
    try {
      if (!this.pickupAddressTarget.value) {
        this.showLocationStatus("Loading address information...", "info");
      }
      const response = await fetch(
        `/places/reverse_geocode?lat=${lat}&lng=${lng}`
      );

      if (!response.ok) {
        throw new Error(`Error: ${response.statusText}`);
      }

      const data = await response.json();

      if (data.error) {
        throw new Error(data.error);
      }

      if (!this.pickupAddressTarget.value) {
        // Update the pickup input with the address
        this.pickupInputTarget.value = data.address;

        // Update the form fields with the location data
        this.updateLocationFields(this.pickupInputTarget, data);

        this.showLocationStatus("Location found!", "success");

        // Also notify the map controller to update
        window.dispatchEvent(
          new CustomEvent("locations:updated", {
            detail: {
              pickupLat: parseFloat(lat),
              pickupLng: parseFloat(lng),
              dropoffLat: this.hasDropoffLatField()
                ? parseFloat(this.dropoffLatTarget.value)
                : null,
              dropoffLng: this.hasDropoffLngField()
                ? parseFloat(this.dropoffLngTarget.value)
                : null,
            },
          })
        );
      } else {
        this.dropoffInputTarget.value = data.address;

        // Update the form fields with the location data
        this.updateLocationFields(this.dropoffInputTarget, data);

        this.showLocationStatus("Location found!", "success");

        // Also notify the map controller to update
        window.dispatchEvent(
          new CustomEvent("locations:updated", {
            detail: {
              pickupLat: this.hasPickupLatField()
                ? parseFloat(this.pickupLatTarget.value)
                : null,
              pickupLng: this.hasPickupLngField()
                ? parseFloat(this.pickupLngTarget.value)
                : null,
              dropoffLat: parseFloat(lat),
              dropoffLng: parseFloat(lng),
            },
          })
        );
      }

      return data;
    } catch (error) {
      console.error("Error in reverse geocoding:", error);
      this.showLocationStatus(
        "Could not find your location. Please try again.",
        "error"
      );
      return null;
    }
  }

  // Show status message
  showLocationStatus(message, type = "info") {
    if (!this.hasLocationStatusTarget) return;

    // Clear any previous status
    this.locationStatusTarget.innerHTML = "";

    // Create status element with appropriate styling
    const statusElement = document.createElement("div");
    statusElement.textContent = message;
    statusElement.className = "py-2 px-3 text-sm rounded-md";

    // Apply color based on status type
    switch (type) {
      case "success":
        statusElement.classList.add("bg-green-100", "text-green-800");
        break;
      case "error":
        statusElement.classList.add("bg-red-100", "text-red-800");
        break;
      case "info":
      default:
        statusElement.classList.add("bg-blue-100", "text-blue-800");
    }

    // Add the status element to the container
    this.locationStatusTarget.appendChild(statusElement);

    // Auto-hide after 5 seconds for success and info messages
    if (type !== "error") {
      setTimeout(() => {
        this.locationStatusTarget.classList.add("opacity-0");
        setTimeout(() => {
          this.locationStatusTarget.innerHTML = "";
          this.locationStatusTarget.classList.remove("opacity-0");
        }, 500);
      }, 5000);
    }
  }

  // Apply consistent styling to the suggestions elements
  applySuggestionsStyle(element) {
    // Most styles are now in the CSS class, but we can add dynamic ones here if needed
    element.addEventListener("mouseenter", () => {
      // Add hover effects, etc. if needed beyond CSS
    });
  }

  fetchSuggestions(event) {
    const query = event.target.value;
    if (query.length < 3) {
      this.clearSuggestions(event.target);
      return;
    }

    this.debouncedFetch(event.target, query);
  }

  performFetch(inputElement, query) {
    fetch(`/places/autocomplete?query=${query}`)
      .then((response) => response.json())
      .then((data) => this.updateSuggestions(inputElement, data, query))
      .catch((error) => console.error("Error fetching places:", error));
  }

  debounce(func, wait) {
    let timeout;
    return (...args) => {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
  }

  updateSuggestions(inputElement, locations, originalQuery) {
    const suggestionsTarget = this.getSuggestionsTarget(inputElement);

    if (inputElement.value !== originalQuery) {
      return;
    }

    suggestionsTarget.innerHTML = "";

    if (locations.length === 0) {
      const noResults = document.createElement("div");
      noResults.textContent = "No locations found";
      noResults.classList.add(
        "px-4",
        "py-2",
        "text-gray-500",
        "italic",
        "text-center"
      );
      suggestionsTarget.appendChild(noResults);
      return;
    }

    locations.forEach((location) => {
      const div = document.createElement("div");
      div.textContent = location.address;
      div.classList.add(
        "autocomplete-item",
        "px-4",
        "py-2",
        "cursor-pointer",
        "hover:bg-gray-100",
        "transition",
        "rounded-md",
        "border-b",
        "border-gray-200",
        "last:border-none"
      );

      div.dataset.latitude = location.latitude;
      div.dataset.longitude = location.longitude;
      div.dataset.address = location.address;

      div.addEventListener("click", (event) =>
        this.selectLocation(event, inputElement, location)
      );

      suggestionsTarget.appendChild(div);
    });
  }

  selectLocation(event, inputElement, location) {
    inputElement.value = location.address;

    this.clearSuggestions(inputElement);

    fetch(`/places/details?place_id=${location.id}`)
      .then((response) => response.json())
      .then((data) =>
        this.updateFormFields(inputElement, { ...location, ...data })
      )
      .catch((error) => console.error("Error fetching place location:", error));
  }

  getSuggestionsTarget(inputElement) {
    return inputElement === this.pickupInputTarget
      ? this.pickupSuggestionsTarget
      : this.dropoffSuggestionsTarget;
  }

  updateFormFields(inputElement, location) {
    if (inputElement === this.pickupInputTarget) {
      if (this.hasPickupAddressTarget) {
        this.pickupAddressTarget.value = location.address;
      }
      this.pickupLatTarget.value = location.latitude;
      this.pickupLngTarget.value = location.longitude;
    } else if (inputElement === this.dropoffInputTarget) {
      if (this.hasDropoffAddressTarget) {
        this.dropoffAddressTarget.value = location.address;
      }
      this.dropoffLatTarget.value = location.latitude;
      this.dropoffLngTarget.value = location.longitude;
    }

    // Add a subtle highlighting effect to show the selected location
    inputElement.classList.add("bg-green-50");
    setTimeout(() => {
      inputElement.classList.remove("bg-green-50");
    }, 500);

    // Notify the map controller about updated locations
    this.notifyLocationChange();
  }

  notifyLocationChange() {
    console.log("Notifying location change with values:", {
      pickupLat: this.hasPickupLatTarget ? this.pickupLatTarget.value : null,
      pickupLng: this.hasPickupLngTarget ? this.pickupLngTarget.value : null,
      dropoffLat: this.hasDropoffLatTarget ? this.dropoffLatTarget.value : null,
      dropoffLng: this.hasDropoffLngTarget ? this.dropoffLngTarget.value : null,
    });

    // Create a detail object with only the valid coordinates
    const detail = {
      pickupLat:
        this.hasPickupLatTarget && this.pickupLatTarget.value
          ? parseFloat(this.pickupLatTarget.value)
          : null,
      pickupLng:
        this.hasPickupLngTarget && this.pickupLngTarget.value
          ? parseFloat(this.pickupLngTarget.value)
          : null,
      dropoffLat:
        this.hasDropoffLatTarget && this.dropoffLatTarget.value
          ? parseFloat(this.dropoffLatTarget.value)
          : null,
      dropoffLng:
        this.hasDropoffLngTarget && this.dropoffLngTarget.value
          ? parseFloat(this.dropoffLngTarget.value)
          : null,
    };

    // Dispatch the event to update the map
    this.dispatch("locationChanged", { detail });

    // Also dispatch a window-level event for components that might be listening
    window.dispatchEvent(new CustomEvent("locations:updated", { detail }));
  }

  clearSuggestions(inputElement) {
    const suggestionsTarget = this.getSuggestionsTarget(inputElement);
    suggestionsTarget.innerHTML = "";
  }

  updateLocationFields(inputElement, location) {
    // Determine if we're updating pickup or dropoff fields
    const isPickup = inputElement === this.pickupInputTarget;

    // Update the appropriate latitude and longitude fields
    if (isPickup) {
      if (this.hasPickupLatTarget && this.hasPickupLngTarget) {
        this.pickupAddressTarget.value = location.address || location.address;
        this.pickupLatTarget.value = location.latitude || location.lat;
        this.pickupLngTarget.value = location.longitude || location.lng;
      }
    } else {
      if (this.hasDropoffLatTarget && this.hasDropoffLngTarget) {
        this.dropoffAddressTarget.value = location.address || location.address;
        this.dropoffLatTarget.value = location.latitude || location.lat;
        this.dropoffLngTarget.value = location.longitude || location.lng;
      }
    }

    // Notify any listeners that locations have been updated
    this.notifyLocationChange();

    // Add a subtle highlighting effect to show the update
    inputElement.classList.add("bg-green-50");
    setTimeout(() => {
      inputElement.classList.remove("bg-green-50");
    }, 1000);
  }

  // Helper to check if dropoff lat field exists
  hasDropoffLatField() {
    return this.hasDropoffLatTarget && this.dropoffLatTarget.value;
  }

  // Helper to check if dropoff lng field exists
  hasDropoffLngField() {
    return this.hasDropoffLngTarget && this.dropoffLngTarget.value;
  }

  // Helper to check if pickup lat field exists
  hasPickupLatField() {
    return this.hasPickupLatTarget && this.pickupLatTarget.value;
  }

  // Helper to check if pickup lng field exists
  hasPickupLngField() {
    return this.hasPickupLngTarget && this.pickupLngTarget.value;
  }

  // Handle location input from either pickup or dropoff fields
  handleLocationInput(inputElement, suggestionsTarget) {
    const query = inputElement.value;
    if (query.length < 3) {
      this.clearSuggestions(inputElement);
      return;
    }

    this.debouncedFetch(inputElement, query);
  }

  // New method to handle the places-autocomplete:locationChanged event
  updateFromPlaces(event) {
    console.log(
      "Received places-autocomplete:locationChanged event",
      event.detail
    );
    const { pickupLat, pickupLng, dropoffLat, dropoffLng } = event.detail;

    this.pickupLatValue = pickupLat;
    this.pickupLngValue = pickupLng;
    this.dropoffLatValue = dropoffLat;
    this.dropoffLngValue = dropoffLng;

    console.log("Updating map with locations from places event");
    this.updateMapWithCurrentLocations();
  }

  async initializeMap() {
    try {
      console.log("Starting map initialization");

      // Fetch map details from our backend
      const mapDetailsResponse = await fetch("/maps/map_details");
      const mapDetails = await mapDetailsResponse.json();
      this.mapDetails = mapDetails; // Store for future use

      // Create a script tag to load Google Maps without exposing API key
      if (!window.google) {
        console.log("Google Maps not loaded yet, loading script");
        await this.loadGoogleMapsScript(mapDetails.script_url);
        console.log("Google Maps script loaded successfully");
      } else {
        console.log("Google Maps already loaded");
      }

      // Create map options - don't include both mapId and styles
      const mapOptions = {
        zoom: 13,
        center: { lat: 0, lng: 0 },
        mapTypeControl: false,
        fullscreenControl: false,
        streetViewControl: false,
      };

      // Use either mapId or styles, not both (mapId takes precedence)
      if (mapDetails.config.mapId) {
        console.log(
          "Creating map instance with mapId:",
          mapDetails.config.mapId
        );
        mapOptions.mapId = mapDetails.config.mapId;
      } else {
        console.log("Creating map instance with custom styles");
        mapOptions.styles = this.getMapStyles();
      }

      this.map = new google.maps.Map(this.mapContainerTarget, mapOptions);
      console.log("Map instance created successfully");

      // Keep track of the current markers and polylines so we can clear them
      this.currentMarkers = [];
      this.currentPolylines = [];

      this.updateMapWithCurrentLocations();
      this.showUserLocation();
      this.enablePinDropFeature();
    } catch (error) {
      console.error("Failed to initialize map:", error);
    }
  }

  // Method to customize map appearance
  getMapStyles() {
    return [
      {
        featureType: "poi",
        elementType: "labels",
        stylers: [{ visibility: "off" }], // Hide points of interest labels for cleaner map
      },
      {
        featureType: "transit",
        elementType: "labels",
        stylers: [{ visibility: "off" }], // Hide transit labels
      },
      {
        featureType: "road",
        elementType: "geometry",
        stylers: [{ color: "#f8f9fa" }], // Lighter road color
      },
    ];
  }

  async loadGoogleMapsScript(scriptUrl) {
    return new Promise((resolve, reject) => {
      window.initGoogleMaps = () => {
        resolve(window.google);
        delete window.initGoogleMaps;
      };

      const script = document.createElement("script");
      script.src = scriptUrl;
      script.async = true;
      script.onerror = (e) => {
        console.error("Google Maps script loading error:", e);
        reject(new Error("Google Maps failed to load"));
      };
      document.head.appendChild(script);
    });
  }

  updateMapWithCurrentLocations() {
    const pickupCoordinates = this.getLocationCoordinates("pickup");
    const dropoffCoordinates = this.getLocationCoordinates("dropoff");

    if (pickupCoordinates) {
      this.createMarker(pickupCoordinates, "P", "origin-marker");

      // Center the map on the pickup location
      this.map.setCenter(pickupCoordinates);
      this.map.setZoom(15); // Zoom in enough to see the area
    }

    if (dropoffCoordinates) {
      this.createMarker(dropoffCoordinates, "D", "destination-marker");
      this.displayRoute(pickupCoordinates, dropoffCoordinates);
    }
  }

  getLocationCoordinates(type) {
    if (type === "pickup" && this.pickupLatValue && this.pickupLngValue) {
      return {
        lat: parseFloat(this.pickupLatValue),
        lng: parseFloat(this.pickupLngValue),
      };
    } else if (
      type === "dropoff" &&
      this.dropoffLatValue &&
      this.dropoffLngValue
    ) {
      return {
        lat: parseFloat(this.dropoffLatValue),
        lng: parseFloat(this.dropoffLngValue),
      };
    }
    return null;
  }

  clearMarker(type) {
    if (!this.currentMarkers) return;

    this.currentMarkers = this.currentMarkers.filter((marker) => {
      if (
        (type === "pickup" && marker.type === "origin-marker") ||
        (type === "dropoff" && marker.type === "destination-marker")
      ) {
        marker.setMap(null); // Remove the marker from the map
        return false; // Exclude this marker from the list
      }
      return true; // Keep other markers
    });
  }

  createMarker(position, label, type) {
    // Clear any existing markers of the same type
    this.currentMarkers =
      this.currentMarkers?.filter((marker) => {
        if (marker.type === type) {
          marker.map = null;
          return false;
        }
        return true;
      }) || [];

    let markerColor = "#367CFF"; // Default blue
    if (type === "origin-marker") {
      markerColor = "#4CAF50"; // Green for pickup
    } else if (type === "destination-marker") {
      markerColor = "#F44336"; // Red for dropoff
    } else if (type === "user-location-marker") {
      markerColor = "#9C27B0"; // Purple for user's current location
    }

    // Create a marker using AdvancedMarkerElement if available
    if (google.maps.marker && google.maps.marker.AdvancedMarkerElement) {
      const markerPin = new google.maps.marker.PinElement({
        background: markerColor,
        borderColor: "#FFFFFF",
        glyphColor: "#FFFFFF",
        glyph: label,
        scale: 1.0,
      });

      const marker = new google.maps.marker.AdvancedMarkerElement({
        position: position,
        map: this.map,
        content: markerPin.element,
        title:
          type === "origin-marker"
            ? "Pickup Location"
            : type === "destination-marker"
            ? "Dropoff Location"
            : "Current Location",
      });

      marker.type = type; // Store the type for later reference
      this.currentMarkers.push(marker);
    } else {
      // Fallback to standard Marker if AdvancedMarkerElement is not available
      const marker = new google.maps.Marker({
        position: position,
        label: label,
        map: this.map,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          fillColor: markerColor,
          fillOpacity: 1,
          strokeWeight: 1,
          strokeColor: "#FFFFFF",
          scale: 8,
        },
      });

      marker.type = type; // Store the type for later reference
      this.currentMarkers.push(marker);
    }
  }

  async displayRoute(origin, destination) {
    try {
      console.log("Fetching route from backend", { origin, destination });
      // Use our backend proxy to get directions
      const originStr = `${origin.lat},${origin.lng}`;
      const destinationStr = `${destination.lat},${destination.lng}`;

      const response = await fetch(
        `/maps/directions?origin=${originStr}&destination=${destinationStr}`
      );
      const routeData = await response.json();
      console.log("Received route data", routeData);

      if (routeData.status === "OK") {
        console.log("Route data OK, rendering on map");

        // Clear existing markers and polylines
        this.currentPolylines.forEach((polyline) => polyline.setMap(null));
        this.currentMarkers.forEach((marker) => (marker.map = null));
        this.currentPolylines = [];
        this.currentMarkers = [];

        // Create a path from the encoded polyline
        const decodedPath = google.maps.geometry.encoding.decodePath(
          routeData.overview_polyline.points
        );

        // Create a polyline to display the route
        const routePolyline = new google.maps.Polyline({
          path: decodedPath,
          strokeColor: "#367CFF",
          strokeOpacity: 1.0,
          strokeWeight: 5,
          map: this.map,
        });
        this.currentPolylines.push(routePolyline);

        // Add markers for the start and end points using AdvancedMarkerElement

        // Pickup marker (green)
        const pickupMarkerPin = new google.maps.marker.PinElement({
          background: "#4CAF50",
          borderColor: "#FFFFFF",
          glyphColor: "#FFFFFF",
          scale: 1.0,
        });

        const startMarker = new google.maps.marker.AdvancedMarkerElement({
          position: origin,
          map: this.map,
          content: pickupMarkerPin.element,
          title: "Pickup Location",
        });
        this.currentMarkers.push(startMarker);

        // Dropoff marker (red)
        const dropoffMarkerPin = new google.maps.marker.PinElement({
          background: "#F44336",
          borderColor: "#FFFFFF",
          glyphColor: "#FFFFFF",
          scale: 1.0,
        });

        const endMarker = new google.maps.marker.AdvancedMarkerElement({
          position: destination,
          map: this.map,
          content: dropoffMarkerPin.element,
          title: "Dropoff Location",
        });
        this.currentMarkers.push(endMarker);

        // Fit the map to show the entire route
        const bounds = new google.maps.LatLngBounds();
        decodedPath.forEach((point) => bounds.extend(point));
        this.map.fitBounds(bounds);

        // Apply route animation
        this.animateRoute(routePolyline);

        // Trigger a custom event with the distance and duration data
        const routeInfoEvent = new CustomEvent("route:calculated", {
          detail: {
            distance: routeData.distance.text,
            duration: routeData.duration.text,
            distance_value: routeData.distance.value, // Raw distance value in meters
            duration_value: routeData.duration.value, // Raw duration value in seconds
            origin: origin,
            destination: destination,
            route_data: {
              distance: routeData.distance,
              duration: routeData.duration,
            },
          },
          bubbles: true,
        });
        console.log(
          "Dispatching route:calculated event",
          routeInfoEvent.detail
        );
        this.element.dispatchEvent(routeInfoEvent);
      } else {
        console.error("Directions request failed due to " + routeData.status);
      }
    } catch (error) {
      console.error("Error fetching directions:", error);
    }
  }

  // Add a route animation
  animateRoute(polyline) {
    const length = google.maps.geometry.spherical.computeLength(
      polyline.getPath()
    );
    const numSteps = Math.min(200, Math.max(20, Math.floor(length / 20)));

    let step = 0;
    const interval = setInterval(() => {
      step++;
      if (step > numSteps) {
        clearInterval(interval);
        return;
      }

      const icons = polyline.get("icons") || [
        {
          icon: {
            path: google.maps.SymbolPath.CIRCLE,
            scale: 7,
            fillColor: "#367CFF",
            fillOpacity: 1,
            strokeColor: "#FFFFFF",
            strokeWeight: 2,
          },
          offset: "0%",
        },
      ];

      icons[0].offset = (step / numSteps) * 100 + "%";
      polyline.set("icons", icons);
    }, 20);
  }

  centerMapOnLocation(location) {
    if (this.map) {
      this.map.setCenter(location);

      // Clear existing markers
      this.currentMarkers.forEach((marker) => (marker.map = null));
      this.currentMarkers = [];

      // Add a new marker for the location using AdvancedMarkerElement
      const markerPin = new google.maps.marker.PinElement({
        background: "#367CFF",
        borderColor: "#FFFFFF",
        glyphColor: "#FFFFFF",
        scale: 1.0,
      });

      const marker = new google.maps.marker.AdvancedMarkerElement({
        position: location,
        map: this.map,
        content: markerPin.element,
        title: "Pickup Location",
      });
      this.currentMarkers.push(marker);
    }
  }

  listenForLocationChanges() {
    // Listen for pickup and dropoff location changes
    console.log("Setting up location change listener");
    this.element.addEventListener("locations:updated", (event) => {
      console.log("Received locations:updated event", event.detail);

      const { pickupLat, pickupLng, dropoffLat, dropoffLng } = event.detail;

      this.pickupLatValue = pickupLat;
      this.pickupLngValue = pickupLng;
      this.dropoffLatValue = dropoffLat;
      this.dropoffLngValue = dropoffLng;

      console.log("Updating map with new locations");
      this.updateMapWithCurrentLocations();
    });

    // Listen for current location usage
    window.addEventListener("use-current-location", () => {
      console.log("Received use-current-location event");
      this.showUserLocation();
    });
  }

  showRouteInfo(event) {
    const distanceText = event.response.routes[0].legs[0].distance.text;
    const durationText = event.response.routes[0].legs[0].duration.text;
    const distanceValue = event.response.routes[0].legs[0].distance.value;
    const durationValue = event.response.routes[0].legs[0].duration.value;

    console.log(
      `Route calculated: ${distanceText} (${distanceValue}m), ${durationText} (${durationValue}s)`
    );

    const routeInfoEvent = new CustomEvent("route:calculated", {
      detail: {
        distance: distanceText,
        duration: durationText,
        distance_value: distanceValue,
        duration_value: durationValue,
        origin: event.response.routes[0].legs[0].start_location,
        destination: event.response.routes[0].legs[0].end_location,
        route_data: {
          distance: {
            text: distanceText,
            value: distanceValue,
          },
          duration: {
            text: durationText,
            value: durationValue,
          },
        },
      },
    });

    document.dispatchEvent(routeInfoEvent);
  }

  showUserLocation() {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const userLocation = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          };

          // Create a special marker for user's location
          this.createMarker(userLocation, "📍", "user-location-marker");

          // Center map on user location
          this.map.setCenter(userLocation);
          this.map.setZoom(15);

          // Dispatch an event that can be used by other controllers
          const event = new CustomEvent("map:user-location-shown", {
            detail: { location: userLocation },
          });
          window.dispatchEvent(event);
        },
        (error) => {
          console.error("Error getting current location:", error);
        },
        {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0,
        }
      );
    }
  }

  enablePinDropFeature() {
    let holdTimeout = null;

    this.map.addListener("mousedown", (event) => {
      holdTimeout = setTimeout(() => {
        this.handlePinDrop(event.latLng);
      }, 1000); // Trigger after holding for 1 second
    });

    this.map.addListener("mouseup", () => {
      clearTimeout(holdTimeout);
    });

    this.map.addListener("mouseout", () => {
      clearTimeout(holdTimeout);
    });
  }

  handlePinDrop(location) {
    window.dispatchEvent(
      new CustomEvent("pin-dropped", {
        detail: {
          lat: location.lat(),
          lng: location.lng(),
        },
      })
    );

    // Update the map with the new locations
    this.updateMapWithCurrentLocations();
  }
}
