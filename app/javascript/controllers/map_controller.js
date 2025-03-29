import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "mapContainer",
    "pickupLat",
    "pickupLng",
    "dropoffLat",
    "dropoffLng",
  ];

  static values = {
    pickupLat: Number,
    pickupLng: Number,
    dropoffLat: Number,
    dropoffLng: Number,
  };

  connect() {
    if (this.hasMapContainerTarget) {
      console.log("Map controller connected, initializing map");
      this.initializeMap();
      this.listenForLocationChanges();
    } else {
      console.log("Map container target not found");
    }
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

    if (pickupCoordinates && dropoffCoordinates) {
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
    console.log("Enabling tap-and-hold pin drop feature");

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
    console.log("Pin dropped at location:", location);

    // Check which input field is selected (pickup or dropoff)
    const selectedInput = document.activeElement;
    // if (
    // selectedInput === this.pickupLatTarget ||
    // selectedInput === this.pickupLngTarget
    // ) {
    this.pickupLatValue = location.lat();
    this.pickupLngValue = location.lng();
    console.log("Saved location as pickup:", {
      lat: this.pickupLatValue,
      lng: this.pickupLngValue,
    });

    window.dispatchEvent(
      new CustomEvent("pin-dropped", {
        detail: {
          lat: this.pickupLatValue,
          lng: this.pickupLngValue,
        },
      })
    );

    // } else if (
    // selectedInput === this.dropoffLatTarget ||
    // selectedInput === this.dropoffLngTarget
    // ) {
    // this.dropoffLatValue = location.lat();
    // this.dropoffLngValue = location.lng();
    // console.log("Saved location as dropoff:", {
    // lat: this.dropoffLatValue,
    // lng: this.dropoffLngValue,
    // });
    // } else {
    // console.log("No input field selected, pin drop ignored");
    // return;
    // }

    // Update the map with the new locations
    this.updateMapWithCurrentLocations();
  }
}
