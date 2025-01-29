import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["location", "distance", "eta"];
  static values = {
    bookingId: String,
    interval: Number,
    googleApiKey: String
  };

  connect() {
    if (this.hasBookingIdValue) {
      this.initializeGoogleMaps().then(() => {
        this.startLocationUpdates();
      }).catch(error => {
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
    
    const apiKey = this.googleApiKeyValue || document.querySelector('meta[name="google-maps-api-key"]')?.content;
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
        this.locationTarget.textContent = data.location?.address || "Cannot get the location";
        this.distanceTarget.textContent = `${data.distance_to_pickup || 'Calculating...'} km`;
        this.etaTarget.textContent = `${data.eta_minutes || 'Calculating...'} minutes`;
        
        // If server-side calculation fails, fallback to client-side
        if (!data.distance_to_pickup && data.location?.coordinates) {
          this.calculateDistanceClientSide(data.location.coordinates);
        }
      }
    } catch (error) {
      console.error("Error fetching driver location:", error);
      this.locationTarget.textContent = "Error getting location";
      this.distanceTarget.textContent = "Unable to calculate";
      this.etaTarget.textContent = "Unable to calculate";
    }
  }

  async calculateDistanceClientSide(coordinates) {
    if (!window.google) {
      console.error("Google Maps not loaded");
      return;
    }

    try {
      const service = new google.maps.DistanceMatrixService();
      const origin = new google.maps.LatLng(
        coordinates.latitude,
        coordinates.longitude
      );
      const destination = this.locationTarget.dataset.address || this.locationTarget.textContent;

      const request = {
        origins: [origin],
        destinations: [destination],
        travelMode: google.maps.TravelMode.DRIVING,
      };

      service.getDistanceMatrix(request, (response, status) => {
        if (status === 'OK' && response.rows[0].elements[0].status === 'OK') {
          const element = response.rows[0].elements[0];
          this.distanceTarget.textContent = element.distance.text;
          this.etaTarget.textContent = element.duration.text;
        } else {
          console.error('Distance calculation failed:', status);
        }
      });
    } catch (error) {
      console.error('Error calculating distance:', error);
    }
  }
}
