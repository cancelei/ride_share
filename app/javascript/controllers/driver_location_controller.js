import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["location", "distance", "eta"];
  static values = {
    bookingId: String,
    interval: Number,
    googleApiKey: String,
    pickupLat: Number,
    pickupLng: Number,
  };

  connect() {
    if (this.hasBookingIdValue) {
      this.intervalValue = this.intervalValue || 60000;
      this.initializeGoogleMaps()
        .then(() => {
          this.startLocationTracking();
          this.startLocationUpdates();
        })
        .catch((error) => {
          console.error("Failed to initialize Google Maps:", error);
        });
    }
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

    return new Promise((resolve, reject) => {
      window.initGoogleMaps = () => {
        resolve(window.google);
        delete window.initGoogleMaps;
      };

      const script = document.createElement("script");
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=geometry&callback=initGoogleMaps&loading=async`;
      script.async = true;
      script.onerror = () => reject(new Error("Google Maps failed to load"));
      document.head.appendChild(script);
    });
  }

  startLocationUpdates() {
    this.updateLocation();
    this.intervalId = setInterval(() => {
      this.updateLocation();
    }, this.intervalValue);
  }

  startLocationTracking() {
    this.intervalId = setInterval(() => {
      this.updateDriverLocation();
    }, this.intervalValue); // 1 minute

    // Initial update
    this.updateDriverLocation();
  }

  async updateDriverLocation() {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(async (position) => {
        const { latitude, longitude } = position.coords;
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
      });
    }
  }

  async updateLocation() {
    try {
      const response = await fetch(
        `/bookings/${this.bookingIdValue}/driver_location`
      );
      const data = await response.json();

      if (data.location) {
        this.locationTarget.textContent =
          data.location?.address || "Location not available";
        this.distanceTarget.textContent = data.distance_to_pickup
          ? `${data.distance_to_pickup} km`
          : "Calculating...";
        this.etaTarget.textContent = data.eta_minutes
          ? `${data.eta_minutes} minutes`
          : "Calculating...";

        if (!data.distance_to_pickup && data.location?.coordinates) {
          this.calculateDistanceClientSide(data.location.coordinates);
        }
      }
    } catch (error) {
      console.error("Error fetching driver location:", error);
      this.locationTarget.textContent = "Location update failed";
      this.distanceTarget.textContent = "Error";
      this.etaTarget.textContent = "Error";
    }
  }

  calculateDistanceClientSide(coordinates) {
    if (!window.google || !this.hasPickupLatValue || !this.hasPickupLngValue) {
      console.error("Required data for calculation not available");
      this.distanceTarget.textContent = "Distance unavailable";
      this.etaTarget.textContent = "ETA unavailable";
      return;
    }

    try {
      const service = new google.maps.DistanceMatrixService();
      const origin = new google.maps.LatLng(
        coordinates.latitude,
        coordinates.longitude
      );
      const destination = new google.maps.LatLng(
        this.pickupLatValue,
        this.pickupLngValue
      );

      service.getDistanceMatrix(
        {
          origins: [origin],
          destinations: [destination],
          travelMode: google.maps.TravelMode.DRIVING,
        },
        (response, status) => {
          if (status === "OK" && response.rows[0].elements[0].status === "OK") {
            const { distance, duration } = response.rows[0].elements[0];
            this.distanceTarget.textContent = distance.text;
            this.etaTarget.textContent = duration.text;
          } else {
            console.error("Distance calculation failed:", status);
            this.distanceTarget.textContent = "Calculation failed";
            this.etaTarget.textContent = "Calculation failed";
          }
        }
      );
    } catch (error) {
      console.error("Error calculating distance:", error);
      this.distanceTarget.textContent = "Error";
      this.etaTarget.textContent = "Error";
    }
  }
}
