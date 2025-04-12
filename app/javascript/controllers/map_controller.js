import { Controller } from "@hotwired/stimulus";

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

// Clear all localStorage
for (let i = 0; i < localStorage.length; i++) {
  const key = localStorage.key(i);
  
  // If the key matches any of our targeted keys or contains any keywords
  if (keysToRemove.includes(key) || keywordsToMatch.some(keyword => key.toLowerCase().includes(keyword))) {
    console.log(`Clearing localStorage item: ${key}`);
    localStorage.removeItem(key);
  }
}

// Clear all sessionStorage
for (let i = 0; i < sessionStorage.length; i++) {
  const key = sessionStorage.key(i);
  
  // If the key matches any of our targeted keys or contains any keywords
  if (keysToRemove.includes(key) || keywordsToMatch.some(keyword => key.toLowerCase().includes(keyword))) {
    console.log(`Clearing sessionStorage item: ${key}`);
    sessionStorage.removeItem(key);
  }
}

// More thorough cookie clearing - clear any cookies that might be related
document.cookie.split(';').forEach(cookie => {
  const cookieName = cookie.split('=')[0].trim();
  
  // If the cookie name matches any of our keywords
  if (keysToRemove.includes(cookieName) || 
      keywordsToMatch.some(keyword => cookieName.toLowerCase().includes(keyword))) {
    console.log(`Clearing cookie: ${cookieName}`);
    document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
  }
});

// Wait for map to initialize before clearing markers and routes

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
"estimatedPrice",
"distanceKm"
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
console.log("Map controller connected - performing JavaScript clobber");

// Initialize user location variables
this.userLat = null;
this.userLng = null;

// Immediately clear all storage to ensure a fresh state on every page load
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
  'dropoffLng',
  'estimatedPrice',
  'distanceKm'
];

// Clear targeted keys from localStorage
keysToRemove.forEach(key => localStorage.removeItem(key));

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
  // Check if the user has previously allowed geolocation
  const userAllowedGeo = localStorage.getItem("userAllowedGeolocation");
  
  if (userAllowedGeo === "true") {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        // Store user location for autocomplete
        this.userLat = latitude;
        this.userLng = longitude;
        console.log("User location stored for autocomplete:", latitude, longitude);
      },
      (error) => {
        console.warn("Could not get location on page load:", error);
      },
      { timeout: 5000, maximumAge: 60000 }
    );
  }
}

// Use the browser's geolocation API to get the current position
useCurrentLocation(event) {
const locationType = event.currentTarget.dataset.type || "pickup";
this.showLocationStatus("Getting your current location...", "info");

navigator.geolocation.getCurrentPosition(
  async (position) => {
    const { latitude, longitude } = position.coords;
    
    // Store user's current location for future autocomplete requests
    this.userLat = latitude;
    this.userLng = longitude;
    
    const isDropoff = locationType === "dropoff";
    await this.reverseGeocode(latitude, longitude, isDropoff);
  },
  (error) => {
    console.error("Geolocation error:", error);
    this.showLocationStatus(
      "Could not get your location. Please check your browser settings and try again.",
      "error"
    );
  },
  { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
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
// Determine if this is for a dropoff location
const isDropoff = inputElement === this.dropoffInputTarget;

// Build the URL with query parameters
let url = `/places/autocomplete?query=${encodeURIComponent(query)}`;

// Add user's current location if available
if (this.userLat && this.userLng) {
  url += `&user_lat=${this.userLat}&user_lng=${this.userLng}`;
}

// If this is a dropoff search and we have pickup coordinates, add them too
if (isDropoff && this.pickupLatValue && this.pickupLngValue) {
  url += `&for_dropoff=true&pickup_lat=${this.pickupLatValue}&pickup_lng=${this.pickupLngValue}`;
}

fetch(url)
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

  // Create and style the name element
  const nameDiv = document.createElement("div");
  nameDiv.textContent = location.name;
  nameDiv.classList.add("font-medium", "text-gray-900");
  
  // Create and style the address element
  const addressDiv = document.createElement("div");
  addressDiv.textContent = location.address;
  addressDiv.classList.add("text-sm", "text-gray-500");

  // Append both elements to the main div
  div.appendChild(nameDiv);
  div.appendChild(addressDiv);

  // Store all necessary data
  div.dataset.latitude = location.location?.latitude;
  div.dataset.longitude = location.location?.longitude;
  div.dataset.address = location.address;
  div.dataset.name = location.name;

  div.addEventListener("click", (event) =>
    this.selectLocation(event, inputElement, location)
  );

  suggestionsTarget.appendChild(div);
});
}

selectLocation(event, inputElement, location) {
  // Use the name as the display value in the input
  inputElement.value = location.name;

  this.clearSuggestions(inputElement);

  // Update form fields with both name and address
  this.updateFormFields(inputElement, {
    ...location,
    display_value: location.name,
    full_address: location.address
  });
}

updateFormFields(inputElement, locationData) {
  const isDropoff = inputElement === this.dropoffInputTarget;
  const addressTarget = isDropoff ? this.dropoffAddressTarget : this.pickupAddressTarget;
  const latTarget = isDropoff ? this.dropoffLatTarget : this.pickupLatTarget;
  const lngTarget = isDropoff ? this.dropoffLngTarget : this.pickupLngTarget;

  // Update the hidden address field with the full address
  addressTarget.value = locationData.full_address;
  
  // Update coordinates if available
  if (locationData.location) {
    const lat = parseFloat(locationData.location.latitude);
    const lng = parseFloat(locationData.location.longitude);

    latTarget.value = lat;
    lngTarget.value = lng;

    // Update the controller values
    if (isDropoff) {
      this.dropoffLatValue = lat;
      this.dropoffLngValue = lng;
    } else {
      this.pickupLatValue = lat;
      this.pickupLngValue = lng;
    }

    // Clear existing marker of the same type
    this.clearMarker(isDropoff ? "dropoff" : "pickup");

    // Create a new marker
    const markerPosition = { lat, lng };
    const markerLabel = isDropoff ? "D" : "P";
    const markerType = isDropoff ? "destination-marker" : "origin-marker";
    this.createMarker(markerPosition, markerLabel, markerType);

    // Center map on the new location
    if (this.map) {
      const newCenter = { lat, lng };
      this.map.setCenter(newCenter);
      this.map.setZoom(16); // Zoom in to show the area clearly

      // If we have both locations, adjust bounds to show both
      if (this.pickupLatValue && this.pickupLngValue && this.dropoffLatValue && this.dropoffLngValue) {
        const bounds = new google.maps.LatLngBounds();
        bounds.extend({ lat: parseFloat(this.pickupLatValue), lng: parseFloat(this.pickupLngValue) });
        bounds.extend({ lat: parseFloat(this.dropoffLatValue), lng: parseFloat(this.dropoffLngValue) });
        this.map.fitBounds(bounds);
        // Add some padding to the bounds
        this.map.setZoom(this.map.getZoom() - 1);
      }
    }
  }

  // Check if we have both pickup and dropoff locations
  const hasPickup = this.pickupLatValue && this.pickupLngValue;
  const hasDropoff = this.dropoffLatValue && this.dropoffLngValue;

  // If we have both locations, calculate the route
  if (hasPickup && hasDropoff) {
    const origin = {
      lat: parseFloat(this.pickupLatValue),
      lng: parseFloat(this.pickupLngValue)
    };
    const destination = {
      lat: parseFloat(this.dropoffLatValue),
      lng: parseFloat(this.dropoffLngValue)
    };
    
    // Calculate route
    this.displayRoute(origin, destination);
  }

  // Dispatch the locations:updated event
  window.dispatchEvent(
    new CustomEvent("locations:updated", {
      detail: {
        pickupLat: !isDropoff ? parseFloat(latTarget.value) : parseFloat(this.pickupLatTarget.value),
        pickupLng: !isDropoff ? parseFloat(lngTarget.value) : parseFloat(this.pickupLngTarget.value),
        dropoffLat: isDropoff ? parseFloat(latTarget.value) : parseFloat(this.dropoffLatTarget.value),
        dropoffLng: isDropoff ? parseFloat(lngTarget.value) : parseFloat(this.dropoffLngTarget.value),
      },
    })
  );
}

getSuggestionsTarget(inputElement) {
return inputElement === this.pickupInputTarget
  ? this.pickupSuggestionsTarget
  : this.dropoffSuggestionsTarget;
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

// Toggle traffic layer
toggleTraffic() {
if (this.trafficLayer) {
  if (this.trafficLayer.getMap()) {
    this.trafficLayer.setMap(null);
  } else {
    this.trafficLayer.setMap(this.map);
  }
} else {
  this.trafficLayer = new google.maps.TrafficLayer();
  this.trafficLayer.setMap(this.map);
}
}

// Handle map click for location selection
handleMapClick(event) {
// Only handle clicks if we're in location selection mode
if (this.locationSelectionMode) {
  const clickedLocation = {
    lat: event.latLng.lat(),
    lng: event.latLng.lng()
  };
  
  // Reverse geocode the clicked location
  this.reverseGeocodeMapClick(clickedLocation);
}
}

// Enable location selection mode
enableLocationSelection(event) {
// Get the type from the button's data attribute
const type = event.currentTarget.dataset.type || 'pickup';

this.locationSelectionMode = type; // 'pickup' or 'dropoff'

// Change cursor to indicate selection mode
this.mapContainerTarget.style.cursor = 'crosshair';

// Show instruction toast
this.showLocationStatus(`Click on the map to select ${type} location`, "info");

console.log(`Location selection mode enabled for ${type}`);
}

// Disable location selection mode
disableLocationSelection() {
this.locationSelectionMode = null;
this.mapContainerTarget.style.cursor = '';
}

// Reverse geocode a clicked location
async reverseGeocodeMapClick(location) {
try {
  const { lat, lng } = location;
  
  // Show loading indicator
  if (this.locationSelectionMode === 'pickup') {
    this.isLoadingPickup = true;
    this.pickupInputTarget.classList.add('loading');
  } else {
    this.isLoadingDropoff = true;
    this.dropoffInputTarget.classList.add('loading');
  }
  
  const response = await fetch(`/places/reverse_geocode?lat=${lat}&lng=${lng}`);
  
  if (!response.ok) {
    throw new Error(`Error: ${response.statusText}`);
  }
  
  const data = await response.json();
  
  if (data.error) {
    throw new Error(data.error);
  }
  
  // Update the appropriate input field
  if (this.locationSelectionMode === 'pickup') {
    this.pickupInputTarget.value = data.address;
    this.pickupAddressTarget.value = data.address;
    this.pickupLatTarget.value = lat;
    this.pickupLngTarget.value = lng;
    this.isLoadingPickup = false;
    this.pickupInputTarget.classList.remove('loading');
  } else {
    this.dropoffInputTarget.value = data.address;
    this.dropoffAddressTarget.value = data.address;
    this.dropoffLatTarget.value = lat;
    this.dropoffLngTarget.value = lng;
    this.isLoadingDropoff = false;
    this.dropoffInputTarget.classList.remove('loading');
  }
  
  // Notify about location change
  this.notifyLocationChange();
  
  // Disable selection mode
  this.disableLocationSelection();
  
} catch (error) {
  console.error("Error in reverse geocoding map click:", error);
  this.showLocationStatus("Could not find address for this location. Please try again.", "error");
  
  // Reset loading state
  if (this.locationSelectionMode === 'pickup') {
    this.isLoadingPickup = false;
    this.pickupInputTarget.classList.remove('loading');
  } else {
    this.isLoadingDropoff = false;
    this.dropoffInputTarget.classList.remove('loading');
  }
  
  // Disable selection mode
  this.disableLocationSelection();
}
}

// Method to customize map appearance
getMapStyles(style = 'default') {
const styles = {
  default: [
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
  ],
  night: [
    { elementType: "geometry", stylers: [{ color: "#242f3e" }] },
    { elementType: "labels.text.stroke", stylers: [{ color: "#242f3e" }] },
    { elementType: "labels.text.fill", stylers: [{ color: "#746855" }] },
    {
      featureType: "administrative.locality",
      elementType: "labels.text.fill",
      stylers: [{ color: "#d59563" }],
    },
    {
      featureType: "poi",
      elementType: "labels.text.fill",
      stylers: [{ color: "#d59563" }],
    },
    {
      featureType: "poi.park",
      elementType: "geometry",
      stylers: [{ color: "#263c3f" }],
    },
    {
      featureType: "poi.park",
      elementType: "labels.text.fill",
      stylers: [{ color: "#6b9a76" }],
    },
    {
      featureType: "road",
      elementType: "geometry",
      stylers: [{ color: "#38414e" }],
    },
    {
      featureType: "road",
      elementType: "geometry.stroke",
      stylers: [{ color: "#212a37" }],
    },
    {
      featureType: "road",
      elementType: "labels.text.fill",
      stylers: [{ color: "#9ca5b3" }],
    },
    {
      featureType: "road.highway",
      elementType: "geometry",
      stylers: [{ color: "#746855" }],
    },
    {
      featureType: "road.highway",
      elementType: "geometry.stroke",
      stylers: [{ color: "#1f2835" }],
    },
    {
      featureType: "road.highway",
      elementType: "labels.text.fill",
      stylers: [{ color: "#f3d19c" }],
    },
    {
      featureType: "transit",
      elementType: "geometry",
      stylers: [{ color: "#2f3948" }],
    },
    {
      featureType: "transit.station",
      elementType: "labels.text.fill",
      stylers: [{ color: "#d59563" }],
    },
    {
      featureType: "water",
      elementType: "geometry",
      stylers: [{ color: "#17263c" }],
    },
    {
      featureType: "water",
      elementType: "labels.text.fill",
      stylers: [{ color: "#515c6d" }],
    },
    {
      featureType: "water",
      elementType: "labels.text.stroke",
      stylers: [{ color: "#17263c" }],
    },
  ],
  silver: [
    {
      elementType: "geometry",
      stylers: [{ color: "#f5f5f5" }],
    },
    {
      elementType: "labels.icon",
      stylers: [{ visibility: "off" }],
    },
    {
      elementType: "labels.text.fill",
      stylers: [{ color: "#616161" }],
    },
    {
      elementType: "labels.text.stroke",
      stylers: [{ color: "#f5f5f5" }],
    },
    {
      featureType: "administrative.land_parcel",
      elementType: "labels.text.fill",
      stylers: [{ color: "#bdbdbd" }],
    },
    {
      featureType: "poi",
      elementType: "geometry",
      stylers: [{ color: "#eeeeee" }],
    },
    {
      featureType: "poi",
      elementType: "labels.text.fill",
      stylers: [{ color: "#757575" }],
    },
    {
      featureType: "poi.park",
      elementType: "geometry",
      stylers: [{ color: "#e5e5e5" }],
    },
    {
      featureType: "poi.park",
      elementType: "labels.text.fill",
      stylers: [{ color: "#9e9e9e" }],
    },
    {
      featureType: "road",
      elementType: "geometry",
      stylers: [{ color: "#ffffff" }],
    },
    {
      featureType: "road.arterial",
      elementType: "labels.text.fill",
      stylers: [{ color: "#757575" }],
    },
    {
      featureType: "road.highway",
      elementType: "geometry",
      stylers: [{ color: "#dadada" }],
    },
    {
      featureType: "road.highway",
      elementType: "labels.text.fill",
      stylers: [{ color: "#616161" }],
    },
    {
      featureType: "road.local",
      elementType: "labels.text.fill",
      stylers: [{ color: "#9e9e9e" }],
    },
    {
      featureType: "transit.line",
      elementType: "geometry",
      stylers: [{ color: "#e5e5e5" }],
    },
    {
      featureType: "transit.station",
      elementType: "geometry",
      stylers: [{ color: "#eeeeee" }],
    },
    {
      featureType: "water",
      elementType: "geometry",
      stylers: [{ color: "#c9c9c9" }],
    },
    {
      featureType: "water",
      elementType: "labels.text.fill",
      stylers: [{ color: "#9e9e9e" }],
    },
  ],
};

return styles[style] || styles.default;
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
} else if (dropoffCoordinates) {
  this.createMarker(dropoffCoordinates, "D", "destination-marker");
  this.map.setCenter(dropoffCoordinates);
  this.map.setZoom(15); // Zoom in enough to see the area
}

if (dropoffCoordinates && pickupCoordinates) {
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

if (type === "user-location-marker") {
  // Create a blue dot with a loading effect for the user's current location
  const markerElement = document.createElement("div");
  markerElement.style.position = "absolute";
  markerElement.style.width = "20px";
  markerElement.style.height = "20px";
  markerElement.style.backgroundColor = "#367CFF";
  markerElement.style.borderRadius = "50%";
  markerElement.style.boxShadow = "0 0 10px rgba(54, 124, 255, 0.5)";
  markerElement.style.animation = "pulse 1.5s infinite";

  const marker = new google.maps.marker.AdvancedMarkerElement({
    position: position,
    map: this.map,
    content: markerElement,
    title: "Current Location",
  });

  marker.type = type; // Store the type for later reference
  this.currentMarkers.push(marker);
} else {
  let markerColor = "#367CFF"; // Default blue
  if (type === "origin-marker") {
    markerColor = "#4CAF50"; // Green for pickup
  } else if (type === "destination-marker") {
    markerColor = "#F44336"; // Red for dropoff
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
          : "Location",
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
}

async displayRoute(origin, destination) {
try {
  // Show loading indicator
  this.showLocationStatus("Calculating route...", "info");
  
  // Use our backend proxy to get directions
  const originStr = `${origin.lat},${origin.lng}`;
  const destinationStr = `${destination.lat},${destination.lng}`;

  const response = await fetch(
    `/maps/directions?origin=${originStr}&destination=${destinationStr}&alternatives=${this.showAlternativeRoutesValue}`
  );
  const routeData = await response.json();

  if (routeData.status === "OK") {
    // Clear existing markers and polylines
    this.clearAllRoutes();

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
    
    // Add alternative routes if available
    if (routeData.alternative_routes && routeData.alternative_routes.length > 0) {
      routeData.alternative_routes.forEach((route, index) => {
        const altPath = google.maps.geometry.encoding.decodePath(
          route.overview_polyline.points
        );
        
        const altPolyline = new google.maps.Polyline({
          path: altPath,
          strokeColor: "#777777",
          strokeOpacity: 0.7,
          strokeWeight: 4,
          map: this.map,
        });
        
        // Add click handler to select this route
        altPolyline.addListener('click', () => {
          this.selectAlternativeRoute(index, route, altPath);
        });
        
        this.alternativeRoutes.push({
          polyline: altPolyline,
          data: route,
          index: index
        });
      });
    }

    // Add markers for the start and end points using AdvancedMarkerElement
    // Make the markers draggable for location adjustment
    
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
      draggable: true,
    });
    
    // Add drag end listener to update pickup location
    startMarker.addListener('dragend', async (event) => {
      const newPosition = startMarker.position;
      this.locationSelectionMode = 'pickup';
      await this.reverseGeocodeMapClick({
        lat: newPosition.lat,
        lng: newPosition.lng
      });
      this.locationSelectionMode = null; // Reset selection mode
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
      draggable: true,
    });
    
    // Add drag end listener to update dropoff location
    endMarker.addListener('dragend', async (event) => {
      const newPosition = endMarker.position;
      this.locationSelectionMode = 'dropoff';
      await this.reverseGeocodeMapClick({
        lat: newPosition.lat,
        lng: newPosition.lng
      });
      this.locationSelectionMode = null; // Reset selection mode
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
    
    console.log("Dispatching route:calculated event", routeInfoEvent.detail);
    this.element.dispatchEvent(routeInfoEvent);
    
    // Update trip info display if available
    if (this.hasTripInfoTarget) {
      this.tripInfoTarget.classList.remove('hidden');
      if (this.hasTripDistanceTarget) {
        this.tripDistanceTarget.textContent = routeData.distance.text;
        this.distanceKmTarget.value = routeData.distance.value / 1000;
      }
      if (this.hasTripDurationTarget) {
        this.tripDurationTarget.textContent = routeData.duration.text;
      }
      if (this.hasTripPriceTarget) {
        // Calculate estimated price (base fare + per km rate)
        const distanceKm = routeData.distance.value / 1000;
        const baseFare = 5.00;
        const perKmRate = 1.50;
        const estimatedPrice = baseFare + (distanceKm * perKmRate);
        this.tripPriceTarget.textContent = `$${estimatedPrice.toFixed(2)}`;
        this.estimatedPriceTarget.value = estimatedPrice;
      }
    }
    
    // Hide loading indicator
    this.showLocationStatus("Route calculated successfully!", "success");
  } else {
    console.error("Directions request failed due to " + routeData.status);
    this.showLocationStatus(`Could not calculate route: ${routeData.status}`, "error");
  }
} catch (error) {
  console.error("Error fetching directions:", error);
  this.showLocationStatus("Error calculating route. Please try again.", "error");
}
}

// Clear all routes and markers
clearAllRoutes() {
// Clear existing polylines
if (this.currentPolylines) {
  this.currentPolylines.forEach(polyline => polyline.setMap(null));
  this.currentPolylines = [];
}

// Clear alternative routes
if (this.alternativeRoutes) {
  this.alternativeRoutes.forEach(route => route.polyline.setMap(null));
  this.alternativeRoutes = [];
}

// Clear markers
if (this.currentMarkers) {
  this.currentMarkers.forEach(marker => {
    if (marker.setMap) marker.setMap(null);
  });
  this.currentMarkers = [];
}
}

// Select an alternative route
selectAlternativeRoute(index, routeData, path) {
// Clear existing polylines but keep markers
this.currentPolylines.forEach(polyline => polyline.setMap(null));
this.currentPolylines = [];

// Update styling of all routes
this.alternativeRoutes.forEach(route => {
  if (route.index === index) {
    // Make the selected route primary
    route.polyline.setOptions({
      strokeColor: "#367CFF",
      strokeOpacity: 1.0,
      strokeWeight: 5
    });
    
    // Add to current polylines
    this.currentPolylines.push(route.polyline);
    
    // Trigger route info update
    const routeInfoEvent = new CustomEvent("route:calculated", {
      detail: {
        distance: routeData.legs[0].distance.text,
        duration: routeData.legs[0].duration.text,
        distance_value: routeData.legs[0].distance.value,
        duration_value: routeData.legs[0].duration.value,
        origin: routeData.legs[0].start_location,
        destination: routeData.legs[0].end_location,
        route_data: {
          distance: routeData.legs[0].distance,
          duration: routeData.legs[0].duration,
        },
      },
      bubbles: true,
    });
    
    this.element.dispatchEvent(routeInfoEvent);
  } else {
    // Make other routes secondary
    route.polyline.setOptions({
      strokeColor: "#777777",
      strokeOpacity: 0.7,
      strokeWeight: 4
    });
  }
});
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
window.addEventListener("use-current-location", (event) => {
  console.log("Received use-current-location event");
  const isDropoff = event.detail?.isDropoff;
  this.showUserLocation(isDropoff);
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

showUserLocation(isDropoff) {
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

// Add this new method to clear all previous ride data
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

// More aggressive clearing of ALL possible storage related to rides
// Clear ALL localStorage items that might be related to the map
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

// Clear all localStorage
for (let i = 0; i < localStorage.length; i++) {
  const key = localStorage.key(i);
  
  // If the key matches any of our targeted keys or contains any keywords
  if (keysToRemove.includes(key) || keywordsToMatch.some(keyword => key.toLowerCase().includes(keyword))) {
    console.log(`Clearing localStorage item: ${key}`);
    localStorage.removeItem(key);
  }
}

// Clear all sessionStorage
for (let i = 0; i < sessionStorage.length; i++) {
  const key = sessionStorage.key(i);
  
  // If the key matches any of our targeted keys or contains any keywords
  if (keysToRemove.includes(key) || keywordsToMatch.some(keyword => key.toLowerCase().includes(keyword))) {
    console.log(`Clearing sessionStorage item: ${key}`);
    sessionStorage.removeItem(key);
  }
}

// More thorough cookie clearing - clear any cookies that might be related
document.cookie.split(';').forEach(cookie => {
  const cookieName = cookie.split('=')[0].trim();
  
  // If the cookie name matches any of our keywords
  if (keysToRemove.includes(cookieName) || 
      keywordsToMatch.some(keyword => cookieName.toLowerCase().includes(keyword))) {
    console.log(`Clearing cookie: ${cookieName}`);
    document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
  }
});

// Wait for map to initialize before clearing markers and routes
if (this.map) {
  console.log("Clearing map markers and routes");
  
  // Clear all markers
  if (this.currentMarkers) {
    this.currentMarkers.forEach(marker => {
      if (marker.setMap) marker.setMap(null);
    });
    this.currentMarkers = [];
  }
  
  // Clear all polylines
  if (this.currentPolylines) {
    this.currentPolylines.forEach(polyline => {
      if (polyline.setMap) polyline.setMap(null);
    });
    this.currentPolylines = [];
  }
  
  // Clear alternative routes
  if (this.alternativeRoutes) {
    this.alternativeRoutes.forEach(route => {
      if (route.polyline && route.polyline.setMap) route.polyline.setMap(null);
    });
    this.alternativeRoutes = [];
  }
  
  // Reset map to default view if possible
  try {
    this.map.setCenter({ lat: 0, lng: 0 });
    this.map.setZoom(13);
  } catch (error) {
    console.log("Could not reset map view:", error);
  }
}

// Dispatch a custom event to notify any other components that we've reset
window.dispatchEvent(new CustomEvent('ride-data-cleared'));

console.log("All previous ride data cleared");
}
}
