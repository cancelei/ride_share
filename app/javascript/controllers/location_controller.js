import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["distance", "time"];
  static values = {
    bookingAddress: String,
    googleApiKey: String,
  };

  connect() {
    if (!this.hasDistanceTarget || !this.hasTimeTarget) {
      console.error("Missing required targets");
      return;
    }

    this.initializeGoogleMaps()
      .then(() => {
        this.startLocationTracking();
      })
      .catch((error) => {
        console.error("Failed to initialize Google Maps:", error);
        this.distanceTarget.textContent = "Unable to load maps";
        this.timeTarget.textContent = "Unable to load maps";
      });
  }

  disconnect() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  }

  async initializeGoogleMaps() {
    if (window.google) return Promise.resolve();

    const apiKey =
      this.googleApiKeyValue ||
      document.querySelector('meta[name="google-maps-api-key"]')?.content;
    if (!apiKey) {
      throw new Error("Google Maps API key not found");
    }

    // Create the script loader
    const loader = new Promise((resolve, reject) => {
      // Create callback for when API is loaded
      window.initGoogleMaps = () => {
        resolve(window.google);
        delete window.initGoogleMaps;
      };

      // Create script element
      const script = document.createElement("script");
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=geometry&callback=initGoogleMaps&loading=async`;
      script.async = true;
      script.onerror = () => reject(new Error("Google Maps failed to load"));

      // Append the script to the DOM
      document.head.appendChild(script);
    });

    return loader;
  }

  startLocationTracking() {
    this.intervalId = setInterval(() => {
      this.updateLocation();
    }, 1000); // 1 minute

    // Initial update
    this.updateLocation();
  }

  async updateLocation() {
    console.log("updateLocation");
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(async (position) => {
        const { latitude, longitude } = position.coords;
        console.log(latitude, longitude);
        // Send location to server
        await fetch("/driver/update_location", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
              .content,
          },
          body: JSON.stringify({ latitude, longitude }),
        });

        // Calculate distance to pickup
        this.calculateDistance(latitude, longitude);
      });
    }
  }

  async calculateDistance(driverLat, driverLng) {
    if (!this.hasDistanceTarget || !this.hasTimeTarget) return;

    try {
      const service = new google.maps.DistanceMatrixService();

      const origin = new google.maps.LatLng(driverLat, driverLng);
      const destination = this.bookingAddressValue;

      const request = {
        origins: [origin],
        destinations: [destination],
        travelMode: google.maps.TravelMode.DRIVING,
      };

      service.getDistanceMatrix(request, (response, status) => {
        if (status === "OK" && response.rows[0].elements[0].status === "OK") {
          const element = response.rows[0].elements[0];
          const distance = element.distance.text;
          const duration = element.duration.text;

          this.distanceTarget.textContent = distance;
          this.timeTarget.textContent = duration;
        } else {
          console.error("Distance calculation failed:", status);
          this.distanceTarget.textContent = "Unable to calculate distance";
          this.timeTarget.textContent = "Unable to calculate time";
        }
      });
    } catch (error) {
      console.error("Error calculating distance:", error);
      this.distanceTarget.textContent = "Error calculating distance";
      this.timeTarget.textContent = "Error calculating time";
    }
  }
}
