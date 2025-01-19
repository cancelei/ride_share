import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["map"];

  connect() {
    this.initMap();
  }

  initMap() {
    const mapElement = this.mapTarget;

    if (!navigator.geolocation) {
      console.error("Geolocation is not supported by this browser.");
      return;
    }

    // Use Geolocation to get the current location
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const currentLocation = {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        };

        // Initialize the map at the current location
        const map = new google.maps.Map(mapElement, {
          center: currentLocation,
          zoom: 14,
        });

        // Add a marker for the current location
        new google.maps.Marker({
          position: currentLocation,
          map: map,
          title: "You are here!",
        });

        console.log("Current Location:", currentLocation);

        // (Optional) Store the current location for use in another page
        this.storeCurrentLocation(currentLocation);
      },
      (error) => {
        console.error("Error fetching location:", error);
      }
    );
  }

  storeCurrentLocation(location) {
    // Save the location to localStorage or send it to your Rails backend
    localStorage.setItem("currentLocation", JSON.stringify(location));
  }
}
