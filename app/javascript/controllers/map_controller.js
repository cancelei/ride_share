import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["mapContainer", "pickupLat", "pickupLng", "dropoffLat", "dropoffLng"];
  
  static values = {
    pickupLat: Number,
    pickupLng: Number,
    dropoffLat: Number,
    dropoffLng: Number
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
    console.log("Received places-autocomplete:locationChanged event", event.detail);
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
      const mapDetailsResponse = await fetch('/maps/map_details');
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
      
      console.log("Creating map instance with mapId:", mapDetails.config.mapId);
      this.map = new google.maps.Map(this.mapContainerTarget, {
        zoom: 13,
        center: { lat: 0, lng: 0 },
        mapTypeControl: false,
        fullscreenControl: false,
        streetViewControl: false,
        mapId: mapDetails.config.mapId || undefined, // Use mapId from backend
        styles: this.getMapStyles() // Add custom map styles
      });
      console.log("Map instance created successfully");

      // Keep track of the current markers and polylines so we can clear them
      this.currentMarkers = [];
      this.currentPolylines = [];

      this.updateMapWithCurrentLocations();
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
        stylers: [{ visibility: "off" }] // Hide points of interest labels for cleaner map
      },
      {
        featureType: "transit",
        elementType: "labels",
        stylers: [{ visibility: "off" }] // Hide transit labels
      },
      {
        featureType: "road",
        elementType: "geometry",
        stylers: [{ color: "#f8f9fa" }] // Lighter road color
      }
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
    console.log("Updating map with locations", {
      hasPickupLat: this.hasPickupLatValue,
      pickupLat: this.pickupLatValue,
      hasPickupLng: this.hasPickupLngValue,
      pickupLng: this.pickupLngValue,
      hasDropoffLat: this.hasDropoffLatValue,
      dropoffLat: this.dropoffLatValue,
      hasDropoffLng: this.hasDropoffLngValue,
      dropoffLng: this.dropoffLngValue
    });
    
    if (this.hasPickupLatValue && this.hasPickupLngValue && this.pickupLatValue && this.pickupLngValue) {
      const pickupLocation = { 
        lat: this.pickupLatValue, 
        lng: this.pickupLngValue 
      };
      
      if (
        this.hasDropoffLatValue && 
        this.hasDropoffLngValue && 
        this.dropoffLatValue && 
        this.dropoffLngValue &&
        this.dropoffLatValue !== null &&
        this.dropoffLngValue !== null
      ) {
        const dropoffLocation = { 
          lat: this.dropoffLatValue, 
          lng: this.dropoffLngValue 
        };
        
        console.log("Both pickup and dropoff locations available, displaying route");
        this.displayRoute(pickupLocation, dropoffLocation);
      } else {
        console.log("Only pickup location available, centering map");
        this.centerMapOnLocation(pickupLocation);
      }
    } else {
      console.log("No locations available yet");
    }
  }

  async displayRoute(origin, destination) {
    try {
      console.log("Fetching route from backend", { origin, destination });
      // Use our backend proxy to get directions
      const originStr = `${origin.lat},${origin.lng}`;
      const destinationStr = `${destination.lat},${destination.lng}`;
      
      const response = await fetch(`/maps/directions?origin=${originStr}&destination=${destinationStr}`);
      const routeData = await response.json();
      console.log("Received route data", routeData);
      
      if (routeData.status === "OK") {
        console.log("Route data OK, rendering on map");
        
        // Clear existing markers and polylines
        this.currentPolylines.forEach(polyline => polyline.setMap(null));
        this.currentMarkers.forEach(marker => marker.map = null);
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
          map: this.map
        });
        this.currentPolylines.push(routePolyline);
        
        // Add markers for the start and end points using AdvancedMarkerElement
        
        // Pickup marker (green)
        const pickupMarkerPin = new google.maps.marker.PinElement({
          background: "#4CAF50",
          borderColor: "#FFFFFF",
          glyphColor: "#FFFFFF",
          scale: 1.0
        });
        
        const startMarker = new google.maps.marker.AdvancedMarkerElement({
          position: origin,
          map: this.map,
          content: pickupMarkerPin.element,
          title: "Pickup Location"
        });
        this.currentMarkers.push(startMarker);
        
        // Dropoff marker (red)
        const dropoffMarkerPin = new google.maps.marker.PinElement({
          background: "#F44336",
          borderColor: "#FFFFFF",
          glyphColor: "#FFFFFF",
          scale: 1.0
        });
        
        const endMarker = new google.maps.marker.AdvancedMarkerElement({
          position: destination,
          map: this.map,
          content: dropoffMarkerPin.element,
          title: "Dropoff Location"
        });
        this.currentMarkers.push(endMarker);
        
        // Fit the map to show the entire route
        const bounds = new google.maps.LatLngBounds();
        decodedPath.forEach(point => bounds.extend(point));
        this.map.fitBounds(bounds);
        
        // Apply route animation
        this.animateRoute(routePolyline);
        
        // Trigger a custom event with the distance and duration data
        const routeInfoEvent = new CustomEvent("route:calculated", {
          detail: { 
            distance: routeData.distance.text, 
            duration: routeData.duration.text 
          },
          bubbles: true
        });
        console.log("Dispatching route:calculated event", routeInfoEvent.detail);
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
    const length = google.maps.geometry.spherical.computeLength(polyline.getPath());
    const numSteps = Math.min(200, Math.max(20, Math.floor(length / 20)));
    
    let step = 0;
    const interval = setInterval(() => {
      step++;
      if (step > numSteps) {
        clearInterval(interval);
        return;
      }
      
      const icons = polyline.get('icons') || [{
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          scale: 7,
          fillColor: "#367CFF",
          fillOpacity: 1,
          strokeColor: "#FFFFFF",
          strokeWeight: 2
        },
        offset: '0%'
      }];
      
      icons[0].offset = (step / numSteps * 100) + '%';
      polyline.set('icons', icons);
    }, 20);
  }

  centerMapOnLocation(location) {
    if (this.map) {
      this.map.setCenter(location);
      
      // Clear existing markers
      this.currentMarkers.forEach(marker => marker.map = null);
      this.currentMarkers = [];
      
      // Add a new marker for the location using AdvancedMarkerElement
      const markerPin = new google.maps.marker.PinElement({
        background: "#367CFF",
        borderColor: "#FFFFFF",
        glyphColor: "#FFFFFF",
        scale: 1.0
      });
      
      const marker = new google.maps.marker.AdvancedMarkerElement({
        position: location,
        map: this.map,
        content: markerPin.element,
        title: "Pickup Location"
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
  }
  
  showRouteInfo(event) {
    // This method handles the route:calculated event dispatched by the map
    // The event data is already being used in the inline script in the view
    console.log("Route calculated:", event.detail);
  }
} 