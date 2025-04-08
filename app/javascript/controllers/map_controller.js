import { Controller } from "@hotwired/stimulus"

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
    "tripInfo",
    "tripDistance",
    "tripDuration",
    "tripPrice",
  ];

  static values = {
    pickupLat: Number,
    pickupLng: Number,
    dropoffLat: Number,
    dropoffLng: Number,
    debounce: { type: Number, default: 300 }, // 300ms debounce
    mapStyle: { type: String, default: "default" },
    showTraffic: { type: Boolean, default: true },
    showAlternativeRoutes: { type: Boolean, default: true },
  };

  connect() {
    // Ensure we're in a truly fresh state
    window.onbeforeunload = () => {
      // Force-clear specific items immediately before page unload
      localStorage.removeItem('userAllowedGeolocation');
      localStorage.removeItem('lastPickupLocation');
      localStorage.removeItem('lastDropoffLocation');
      sessionStorage.clear(); // Aggressively clear all session storage
    };
    
    // Clear all previous data on page load
    this.clearPreviousRideData();
    
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
    
    // Initialize loading indicators
    this.isLoadingPickup = false;
    this.isLoadingDropoff = false;
    
    // Add click listener to map for location selection
    this.mapClickListener = this.handleMapClick.bind(this);
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

    // Clear existing markers and route
    if (this.currentMarkers) {
      this.currentMarkers.forEach(marker => marker.setMap(null));
      this.currentMarkers = this.currentMarkers.filter(marker => 
        (type === "pickup" && marker.type !== "origin-marker") || 
        (type === "dropoff" && marker.type !== "destination-marker")
      );
    }
    
    if (this.currentPolylines) {
      this.currentPolylines.forEach(polyline => polyline.setMap(null));
      this.currentPolylines = [];
    }

    // Notify any listeners that locations have been cleared
    this.notifyLocationChange();
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
  useCurrentLocation(event) {
    console.log("useCurrentLocation called with event:", event);
    
    if (!navigator.geolocation) {
      this.showLocationStatus(
        "Geolocation is not supported by your browser",
        "error"
      );
      return;
    }

    // Get the type from the button's data attribute if event exists
    const isDropoff = event && event.currentTarget ? event.currentTarget.dataset.type === 'dropoff' : false;
    console.log(`Using current location for ${isDropoff ? 'dropoff' : 'pickup'}`);
    
    // First, properly clear the location (using the same function as the X button)
    if (isDropoff) {
      this.clearDropoffLocation(); // Use the method that the X button uses
      console.log("Cleared dropoff location");
    } else {
      this.clearPickupLocation(); // Use the method that the X button uses
      console.log("Cleared pickup location");
    }
    
    // Show loading status
    this.showLocationStatus(`Getting your ${isDropoff ? 'dropoff' : 'pickup'} location...`, "info");
    
    // Show loading indicator in the input field
    if (isDropoff && this.hasDropoffInputTarget) {
      this.dropoffInputTarget.classList.add('loading');
    } else if (!isDropoff && this.hasPickupInputTarget) {
      this.pickupInputTarget.classList.add('loading');
    }

    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const { latitude, longitude } = position.coords;
        console.log(`Got coordinates: ${latitude}, ${longitude} for ${isDropoff ? 'dropoff' : 'pickup'}`);
        
        try {
          // Update controller values directly first
          if (isDropoff) {
            this.dropoffLatValue = latitude;
            this.dropoffLngValue = longitude;
            // Also update form fields directly to ensure they're set
            if (this.hasDropoffLatTarget) this.dropoffLatTarget.value = latitude;
            if (this.hasDropoffLngTarget) this.dropoffLngTarget.value = longitude;
            console.log("Set dropoff values directly:", this.dropoffLatTarget.value, this.dropoffLngTarget.value);
          } else {
            this.pickupLatValue = latitude;
            this.pickupLngValue = longitude;
            // Also update form fields directly to ensure they're set
            if (this.hasPickupLatTarget) this.pickupLatTarget.value = latitude;
            if (this.hasPickupLngTarget) this.pickupLngTarget.value = longitude;
            console.log("Set pickup values directly:", this.pickupLatTarget.value, this.pickupLngTarget.value);
          }
        
          // Get address with reverse geocoding
          const targetInput = isDropoff ? this.dropoffInputTarget : this.pickupInputTarget;
          const targetAddress = isDropoff ? this.dropoffAddressTarget : this.pickupAddressTarget;
          
          // Make a specific request for reverse geocoding
          const response = await fetch(`/places/reverse_geocode?lat=${latitude}&lng=${longitude}`);
          
          if (!response.ok) {
            throw new Error(`Error: ${response.statusText}`);
          }
          
          const data = await response.json();
          console.log("Reverse geocode data:", data);
          
          if (data.error) {
            throw new Error(data.error);
          }
          
          // Update the input fields directly
          targetInput.value = data.address;
          targetAddress.value = data.address;
          console.log(`Set ${isDropoff ? 'dropoff' : 'pickup'} address to: ${data.address}`);
          
          // Remove loading indicator
          if (isDropoff && this.hasDropoffInputTarget) {
            this.dropoffInputTarget.classList.remove('loading');
          } else if (!isDropoff && this.hasPickupInputTarget) {
            this.pickupInputTarget.classList.remove('loading');
          }
          
          // Update the map with the new location
          console.log("Updating map after setting location");
          this.updateMapWithCurrentLocations();
          
          // Store permission in localStorage for future use
          localStorage.setItem("userAllowedGeolocation", "true");
          
          // Show success message
          this.showLocationStatus(`${isDropoff ? 'Dropoff' : 'Pickup'} location set to your current location`, "success");
          
          // Notify other components about location update
          const locationEvent = new CustomEvent("locations:updated", { 
            detail: {
              pickupLat: this.hasPickupLatTarget ? parseFloat(this.pickupLatTarget.value) : null,
              pickupLng: this.hasPickupLngTarget ? parseFloat(this.pickupLngTarget.value) : null,
              dropoffLat: this.hasDropoffLatTarget ? parseFloat(this.dropoffLatTarget.value) : null,
              dropoffLng: this.hasDropoffLngTarget ? parseFloat(this.dropoffLngTarget.value) : null,
            }
          });
          
          console.log("Dispatching locations:updated event with values:", locationEvent.detail);
          window.dispatchEvent(locationEvent);
        } catch (error) {
          console.error("Error in setting current location:", error);
          this.showLocationStatus(`Error setting ${isDropoff ? 'dropoff' : 'pickup'} location: ${error.message}`, "error");
          
          // Remove loading indicator
          if (isDropoff && this.hasDropoffInputTarget) {
            this.dropoffInputTarget.classList.remove('loading');
          } else if (!isDropoff && this.hasPickupInputTarget) {
            this.pickupInputTarget.classList.remove('loading');
          }
        }
      },
      (error) => {
        console.error("Geolocation error:", error);
        let errorMsg = "Error getting your location.";

        switch (error.code) {
          case error.PERMISSION_DENIED:
            errorMsg = "Location access denied. Please enable location services.";
            localStorage.removeItem("userAllowedGeolocation");
            break;
          case error.POSITION_UNAVAILABLE:
            errorMsg = "Location information is unavailable.";
            break;
          case error.TIMEOUT:
            errorMsg = "Location request timed out.";
            break;
        }

        // Remove loading indicator
        if (isDropoff && this.hasDropoffInputTarget) {
          this.dropoffInputTarget.classList.remove('loading');
        } else if (!isDropoff && this.hasPickupInputTarget) {
          this.pickupInputTarget.classList.remove('loading');
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
  async reverseGeocode(lat, lng, isDropoff = false) {
    try {
      const targetInput = isDropoff ? this.dropoffInputTarget : this.pickupInputTarget;
      const targetAddress = isDropoff ? this.dropoffAddressTarget : this.pickupAddressTarget;

      this.showLocationStatus("Loading address information...", "info");
      
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

      // Update the input with the address
      targetInput.value = data.address;

      // Update the form fields with the location data
      this.updateLocationFields(targetInput, data);

      this.showLocationStatus("Location found!", "success");

      // Also notify the map controller to update
      window.dispatchEvent(
        new CustomEvent("locations:updated", {
          detail: {
            pickupLat: isDropoff ? 
              (this.hasPickupLatField() ? parseFloat(this.pickupLatTarget.value) : null) : 
              parseFloat(lat),
            pickupLng: isDropoff ? 
              (this.hasPickupLngField() ? parseFloat(this.pickupLngTarget.value) : null) : 
              parseFloat(lng),
            dropoffLat: isDropoff ? parseFloat(lat) : 
              (this.hasDropoffLatField() ? parseFloat(this.dropoffLatTarget.value) : null),
            dropoffLng: isDropoff ? parseFloat(lng) : 
              (this.hasDropoffLngField() ? parseFloat(this.dropoffLngTarget.value) : null),
          },
        })
      );

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
      if (event.target === this.pickupInputTarget) {
        this.clearPickupLocation();
      } else if (event.target === this.dropoffInputTarget) {
        this.clearDropoffLocation();
      }
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
        // await this.loadGoogleMapsScript(mapDetails.script_url);
        console.log("Google Maps script loaded successfully");
      } else {
        console.log("Google Maps already loaded");
      }

      // Create map options - don't include both mapId and styles
      const mapOptions = {
        zoom: 13,
        center: { lat: 0, lng: 0 },
        mapTypeControl: true,
        mapTypeControlOptions: {
          style: google.maps.MapTypeControlStyle.DROPDOWN_MENU,
          position: google.maps.ControlPosition.TOP_RIGHT
        },
        fullscreenControl: true,
        fullscreenControlOptions: {
          position: google.maps.ControlPosition.RIGHT_TOP
        },
        streetViewControl: true,
        streetViewControlOptions: {
          position: google.maps.ControlPosition.RIGHT_BOTTOM
        },
        zoomControl: true,
        zoomControlOptions: {
          position: google.maps.ControlPosition.RIGHT_CENTER
        }
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
        mapOptions.styles = this.getMapStyles(this.mapStyleValue);
      }

      this.map = new google.maps.Map(this.mapContainerTarget, mapOptions);
      console.log("Map instance created successfully");

      // Keep track of the current markers and polylines so we can clear them
      this.currentMarkers = [];
      this.currentPolylines = [];
      this.alternativeRoutes = [];
      
      // Add traffic layer if enabled
      if (this.showTrafficValue) {
        this.trafficLayer = new google.maps.TrafficLayer();
        this.trafficLayer.setMap(this.map);
      }
      
      // Add click listener to map for location selection
      this.map.addListener('click', this.mapClickListener);

      this.updateMapWithCurrentLocations();
      this.showUserLocation();
      this.enablePinDropFeature();
      
      // Add custom controls
      this.addCustomControls();
      
    } catch (error) {
      console.error("Failed to initialize map:", error);
    }
  }
  
  // Add custom controls to the map
  addCustomControls() {
    // Traffic toggle control
    const trafficControlDiv = document.createElement('div');
    trafficControlDiv.className = 'custom-map-control';
    trafficControlDiv.innerHTML = `
      <button class="map-control-button ${this.showTrafficValue ? 'active' : ''}">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"></circle>
          <line x1="12" y1="16" x2="12" y2="12"></line>
          <line x1="12" y1="8" x2="12" y2="8"></line>
        </svg>
        <span>Traffic</span>
      </button>
    `;
    
    trafficControlDiv.querySelector('button').addEventListener('click', () => {
      this.toggleTraffic();
      trafficControlDiv.querySelector('button').classList.toggle('active');
    });
    
    this.map.controls[google.maps.ControlPosition.TOP_LEFT].push(trafficControlDiv);
    
    // My location control
    const myLocationDiv = document.createElement('div');
    myLocationDiv.className = 'custom-map-control';
    myLocationDiv.innerHTML = `
      <button class="map-control-button">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"></circle>
          <point cx="12" cy="12" r="3"></point>
        </svg>
        <span>My Location</span>
      </button>
    `;
    
    myLocationDiv.querySelector('button').addEventListener('click', () => {
      this.showUserLocation();
    });
    
    this.map.controls[google.maps.ControlPosition.RIGHT_BOTTOM].push(myLocationDiv);
  }
  
  // Add a method to clear all previous ride data
  clearPreviousRideData() {
    console.log("Clearing all previous ride data on page load");
    
    // Clear form fields immediately
    if (this.hasPickupInputTarget) this.pickupInputTarget.value = "";
    if (this.hasPickupAddressTarget) this.pickupAddressTarget.value = "";
    if (this.hasPickupLatTarget) this.pickupLatTarget.value = "";
    if (this.hasPickupLngTarget) this.pickupLngTarget.value = "";
    
    if (this.hasDropoffInputTarget) this.dropoffInputTarget.value = "";
    if (this.hasDropoffAddressTarget) this.dropoffAddressTarget.value = "";
    if (this.hasDropoffLatTarget) this.dropoffLatTarget.value = "";
    if (this.hasDropoffLngTarget) this.dropoffLngTarget.value = "";
    
    // Reset controller values
    this.pickupLatValue = null;
    this.pickupLngValue = null;
    this.dropoffLatValue = null;
    this.dropoffLngValue = null;
    
    // Hide trip info if it exists
    if (this.hasTripInfoTarget) {
      this.tripInfoTarget.classList.add('hidden');
    }
    
    // Clear local storage items
    const keysToRemove = [
      'userAllowedGeolocation',
      'lastPickupLocation',
      'lastDropoffLocation',
      'lastRoute',
      'mapState',
      'rideData',
      'pickupAddress',
      'dropoffAddress',
      'pickupLat',
      'pickupLng',
      'dropoffLat',
      'dropoffLng'
    ];
    
    // Search for any items that might contain these keywords
    const keywordsToMatch = ['pickup', 'dropoff', 'location', 'ride', 'map', 'route', 'geocode'];
    
    // Clear localStorage items
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (keysToRemove.includes(key) || keywordsToMatch.some(keyword => key.toLowerCase().includes(keyword))) {
        console.log(`Clearing localStorage item: ${key}`);
        localStorage.removeItem(key);
      }
    }
    
    // Clear sessionStorage items
    for (let i = 0; i < sessionStorage.length; i++) {
      const key = sessionStorage.key(i);
      if (keysToRemove.includes(key) || keywordsToMatch.some(keyword => key.toLowerCase().includes(keyword))) {
        console.log(`Clearing sessionStorage item: ${key}`);
        sessionStorage.removeItem(key);
      }
    }
    
    // Clear related cookies
    document.cookie.split(';').forEach(cookie => {
      const cookieName = cookie.split('=')[0].trim();
      if (keysToRemove.includes(cookieName) || 
          keywordsToMatch.some(keyword => cookieName.toLowerCase().includes(keyword))) {
        console.log(`Clearing cookie: ${cookieName}`);
        document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
      }
    });
    
    console.log("All previous ride data cleared");
  }
}

