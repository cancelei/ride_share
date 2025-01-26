import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["location", "distance", "eta"];
  static values = {
    bookingId: String,
    interval: Number,
  };

  connect() {
    if (this.hasBookingIdValue) {
      this.startLocationUpdates();
    }
  }

  disconnect() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  }

  startLocationUpdates() {
    this.updateLocation();
    this.intervalId = setInterval(() => {
      this.updateLocation();
    }, this.intervalValue || 60000);
  }

  async updateLocation() {
    try {
      const response = await fetch(
        `/bookings/${this.bookingIdValue}/driver_location`
      );
      const data = await response.json();

      if (data.location) {
        this.locationTarget.textContent =
          data.location?.address || "Cannot get the location";
        this.distanceTarget.textContent = `${data.distance_to_pickup} km`;
        this.etaTarget.textContent = `${data.eta_minutes} minutes`;
      }
    } catch (error) {
      console.error("Error fetching driver location:", error);
    }
  }
}
