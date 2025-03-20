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
  }
  
  // Apply consistent styling to the suggestions elements
  applySuggestionsStyle(element) {
    // Most styles are now in the CSS class, but we can add dynamic ones here if needed
    element.addEventListener('mouseenter', () => {
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
      this.pickupAddressTarget.value = location.address;
      this.pickupLatTarget.value = location.latitude;
      this.pickupLngTarget.value = location.longitude;
    } else if (inputElement === this.dropoffInputTarget) {
      this.dropoffAddressTarget.value = location.address;
      this.dropoffLatTarget.value = location.latitude;
      this.dropoffLngTarget.value = location.longitude;
    }
    
    // Add a subtle highlighting effect to show the selected location
    inputElement.classList.add('bg-green-50');
    setTimeout(() => {
      inputElement.classList.remove('bg-green-50');
    }, 500);
    
    // Notify the map controller about updated locations
    this.notifyLocationChange();
  }
  
  notifyLocationChange() {
    // Only dispatch the event if we have both pickup and dropoff coordinates
    if (
      this.pickupLatTarget.value && 
      this.pickupLngTarget.value && 
      this.dropoffLatTarget.value && 
      this.dropoffLngTarget.value
    ) {
      console.log("Notifying location change:", {
        pickupLat: parseFloat(this.pickupLatTarget.value),
        pickupLng: parseFloat(this.pickupLngTarget.value),
        dropoffLat: parseFloat(this.dropoffLatTarget.value),
        dropoffLng: parseFloat(this.dropoffLngTarget.value)
      });
      
      // Use Stimulus dispatch instead of regular CustomEvent
      // This will send the event through the Stimulus system which handles controller communication
      this.dispatch("locationChanged", { 
        detail: {
          pickupLat: parseFloat(this.pickupLatTarget.value),
          pickupLng: parseFloat(this.pickupLngTarget.value),
          dropoffLat: parseFloat(this.dropoffLatTarget.value),
          dropoffLng: parseFloat(this.dropoffLngTarget.value)
        }
      });
      
      // Update the map controller targets if they exist
      const pickupLatInput = document.querySelector('[data-map-target="pickupLat"]');
      const pickupLngInput = document.querySelector('[data-map-target="pickupLng"]');
      const dropoffLatInput = document.querySelector('[data-map-target="dropoffLat"]');
      const dropoffLngInput = document.querySelector('[data-map-target="dropoffLng"]');
      
      if (pickupLatInput) pickupLatInput.value = this.pickupLatTarget.value;
      if (pickupLngInput) pickupLngInput.value = this.pickupLngTarget.value;
      if (dropoffLatInput) dropoffLatInput.value = this.dropoffLatTarget.value;
      if (dropoffLngInput) dropoffLngInput.value = this.dropoffLngTarget.value;

    } else {
      // For debugging only - even if we only have pickup coordinates, center the map there
      if (this.pickupLatTarget.value && this.pickupLngTarget.value) {
        console.log("Only pickup location available, updating map with single location");
        this.dispatch("locationChanged", { 
          detail: {
            pickupLat: parseFloat(this.pickupLatTarget.value),
            pickupLng: parseFloat(this.pickupLngTarget.value),
            dropoffLat: null,
            dropoffLng: null
          }
        });
        
        // Update the map controller targets if they exist
        const pickupLatInput = document.querySelector('[data-map-target="pickupLat"]');
        const pickupLngInput = document.querySelector('[data-map-target="pickupLng"]');
        
        if (pickupLatInput) pickupLatInput.value = this.pickupLatTarget.value;
        if (pickupLngInput) pickupLngInput.value = this.pickupLngTarget.value;
      } else {
        console.log("Missing coordinates for location change:", {
          pickupLat: this.pickupLatTarget.value,
          pickupLng: this.pickupLngTarget.value,
          dropoffLat: this.dropoffLatTarget.value,
          dropoffLng: this.dropoffLngTarget.value
        });
      }
    }
  }

  clearSuggestions(inputElement) {
    const suggestionsTarget = this.getSuggestionsTarget(inputElement);
    suggestionsTarget.innerHTML = "";
    suggestionsTarget.style.display = "none";
  }
}
