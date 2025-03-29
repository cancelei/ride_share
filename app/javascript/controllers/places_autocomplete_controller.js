import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
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
    debounce: { type: Number, default: 300 }, // 300ms debounce
  };

  connect() {
    this.debouncedFetch = this.debounce(
      this.performFetch.bind(this),
      this.debounceValue
    );
    console.log("Places autocomplete controller connected");

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
  }

  addLocationListener() {
    window.addEventListener("pin-dropped", (event) => {
      console.log(event, event.detail);
      this.pinDropped(event.detail);
    });
  }

  pinDropped(detail) {
    const { lat: latitude, lng: longitude } = detail;
    console.log("Pin dropped at:", latitude, longitude);
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
    suggestionsTarget.style.display = "block";

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
    suggestionsTarget.style.display = "none";
  }

  updateLocationFields(inputElement, location) {
    // Determine if we're updating pickup or dropoff fields
    const isPickup = inputElement === this.pickupInputTarget;

    // Update the appropriate latitude and longitude fields
    if (isPickup) {
      if (this.hasPickupLatTarget && this.hasPickupLngTarget) {
        this.pickupLatTarget.value = location.latitude || location.lat;
        this.pickupLngTarget.value = location.longitude || location.lng;
      }
    } else {
      if (this.hasDropoffLatTarget && this.hasDropoffLngTarget) {
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

  // Handle location input from either pickup or dropoff fields
  handleLocationInput(inputElement, suggestionsTarget) {
    const query = inputElement.value;
    if (query.length < 3) {
      this.clearSuggestions(inputElement);
      return;
    }

    this.debouncedFetch(inputElement, query);
  }
}
