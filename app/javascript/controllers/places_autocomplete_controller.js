import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pickup", "dropoff"]

  connect() {
    this.initializeGoogleMaps().then(() => {
      this.initializeAutocomplete()
    }).catch(error => {
      console.error("Failed to initialize Google Maps:", error)
    })
  }

  async initializeGoogleMaps() {
    if (window.google) return Promise.resolve()
    
    const apiKey = this.getApiKey();
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
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=places&callback=initGoogleMaps&loading=async`;
      script.async = true;
      script.onerror = () => reject(new Error("Google Maps failed to load"));
      
      // Append the script to the DOM
      document.head.appendChild(script);
    });

    return loader;
  }

  initializeAutocomplete() {
    const options = {
      componentRestrictions: { country: "hn" },
      fields: ["formatted_address", "geometry", "name"],
      strictBounds: false
    }

    this.pickupAutocomplete = new google.maps.places.Autocomplete(
      this.pickupTarget,
      options
    )

    this.dropoffAutocomplete = new google.maps.places.Autocomplete(
      this.dropoffTarget,
      options
    )

    // Initialize Distance Matrix Service
    this.distanceService = new google.maps.DistanceMatrixService()

    this.pickupAutocomplete.addListener('place_changed', () => {
      const place = this.pickupAutocomplete.getPlace()
      if (!place.geometry) return

      // Store pickup location data in hidden fields
      this.setLocationFields('pickup', place)
      this.calculateDistanceAndDuration()
    })

    this.dropoffAutocomplete.addListener('place_changed', () => {
      const place = this.dropoffAutocomplete.getPlace()
      if (!place.geometry) return

      // Store dropoff location data in hidden fields
      this.setLocationFields('dropoff', place)
      this.calculateDistanceAndDuration()
    })
  }

  setLocationFields(type, place) {
    const prefix = type === 'pickup' ? 'pickup' : 'dropoff'
    
    // Update or create hidden fields
    this.ensureHiddenField(`booking_${prefix}_location_attributes_address`, place.formatted_address)
    this.ensureHiddenField(`booking_${prefix}_location_attributes_latitude`, place.geometry.location.lat())
    this.ensureHiddenField(`booking_${prefix}_location_attributes_longitude`, place.geometry.location.lng())
    this.ensureHiddenField(`booking_${prefix}_location_attributes_location_type`, type)
  }

  ensureHiddenField(name, value) {
    let field = document.querySelector(`input[name="booking[${name}]"]`)
    if (!field) {
      field = document.createElement('input')
      field.type = 'hidden'
      field.name = `booking[${name}]`
      this.element.appendChild(field)
    }
    field.value = value
  }

  calculateDistanceAndDuration() {
    const pickup = this.pickupAutocomplete.getPlace()
    const dropoff = this.dropoffAutocomplete.getPlace()

    if (!pickup?.geometry || !dropoff?.geometry) return

    const request = {
      origins: [{ lat: pickup.geometry.location.lat(), lng: pickup.geometry.location.lng() }],
      destinations: [{ lat: dropoff.geometry.location.lat(), lng: dropoff.geometry.location.lng() }],
      travelMode: google.maps.TravelMode.DRIVING,
    }

    this.distanceService.getDistanceMatrix(request, (response, status) => {
      if (status === 'OK' && response.rows[0].elements[0].status === 'OK') {
        const result = response.rows[0].elements[0]
        
        // Store distance and duration in hidden fields
        this.ensureHiddenField('distance_km', (result.distance.value / 1000).toFixed(2))
        this.ensureHiddenField('estimated_duration_minutes', Math.round(result.duration.value / 60))
        this.ensureHiddenField('total_travel_duration_minutes', Math.round(result.duration.value / 60))
      }
    })
  }

  getApiKey() {
    const metaTag = document.querySelector('meta[name="google-maps-api-key"]')
    return metaTag ? metaTag.content : null
  }
}