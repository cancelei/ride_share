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

  fetchSuggestions(event) {
    const query = event.target.value;
    if (query.length < 3) {
      this.clearSuggestions(event.target);
      return;
    }

    fetch(`/places/autocomplete?query=${query}`)
      .then((response) => response.json())
      .then((data) => this.updateSuggestions(event.target, data))
      .catch((error) => console.error("Error fetching places:", error));
  }

  updateSuggestions(inputElement, locations) {
    const suggestionsTarget = this.getSuggestionsTarget(inputElement);
    suggestionsTarget.innerHTML = "";
    suggestionsTarget.style.display = "block";

    locations.forEach((location) => {
      const div = document.createElement("div");
      div.textContent = location.address;
      div.classList.add("autocomplete-item");
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

    if (inputElement === this.pickupInputTarget) {
      this.pickupAddressTarget.value = location.address;
      this.pickupLatTarget.value = location.latitude;
      this.pickupLngTarget.value = location.longitude;
    } else if (inputElement === this.dropoffInputTarget) {
      this.dropoffAddressTarget.value = location.address;
      this.dropoffLatTarget.value = location.latitude;
      this.dropoffLngTarget.value = location.longitude;
    }

    this.clearSuggestions(inputElement);
  }

  getSuggestionsTarget(inputElement) {
    return inputElement === this.pickupInputTarget
      ? this.pickupSuggestionsTarget
      : this.dropoffSuggestionsTarget;
  }

  clearSuggestions(inputElement) {
    const suggestionsTarget = this.getSuggestionsTarget(inputElement);
    suggestionsTarget.innerHTML = "";
    suggestionsTarget.style.display = "none";
  }
}
