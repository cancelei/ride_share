import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "pickup", "dropoff",
    "pickupAddress", "pickupLat", "pickupLng",
    "dropoffAddress", "dropoffLat", "dropoffLng"
  ]

  connect() {
    this.initializeGoogleMaps()
      .then(() => {
        this.initializeAutocomplete();
      })
      .catch((error) => {
        console.error("Failed to initialize Google Maps:", error);
      });
  }

  async initializeGoogleMaps() {
    if (window.google) return Promise.resolve();

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
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=places,geometry&callback=initGoogleMaps&loading=async`;
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
      fields: ["address_components", "formatted_address", "geometry", "name"],
      strictBounds: false,
    };

    this.pickupAutocomplete = new google.maps.places.Autocomplete(
      this.pickupTarget,
      options
    );

    this.dropoffAutocomplete = new google.maps.places.Autocomplete(
      this.dropoffTarget,
      options
    );

    // Initialize Distance Matrix Service
    this.distanceService = new google.maps.DistanceMatrixService();

    this.setupPlaceChangedListeners();
  }

  setupPlaceChangedListeners() {
    this.pickupAutocomplete.addListener("place_changed", () => {
      const place = this.pickupAutocomplete.getPlace();
      if (!place.geometry) return;
      
      // Update pickup location fields
      this.pickupAddressTarget.value = place.formatted_address;
      this.pickupLatTarget.value = place.geometry.location.lat();
      this.pickupLngTarget.value = place.geometry.location.lng();
      
      this.calculateDistanceAndDuration();
    });

    this.dropoffAutocomplete.addListener("place_changed", () => {
      const place = this.dropoffAutocomplete.getPlace();
      if (!place.geometry) return;
      
      // Update dropoff location fields
      this.dropoffAddressTarget.value = place.formatted_address;
      this.dropoffLatTarget.value = place.geometry.location.lat();
      this.dropoffLngTarget.value = place.geometry.location.lng();
      
      this.calculateDistanceAndDuration();
    });
  }

  ensureHiddenField(name, value) {
    let field = document.querySelector(`input[name="ride[${name}]"]`);
    if (!field) {
      field = document.createElement("input");
      field.type = "hidden";
      field.name = `ride[${name}]`;
      this.element.appendChild(field);
    }
    field.value = value;
  }

  calculateDistanceAndDuration() {
    const pickup = this.pickupAutocomplete.getPlace();
    const dropoff = this.dropoffAutocomplete.getPlace();

    if (!pickup?.geometry || !dropoff?.geometry) return;

    const request = {
      origins: [
        {
          lat: pickup.geometry.location.lat(),
          lng: pickup.geometry.location.lng(),
        },
      ],
      destinations: [
        {
          lat: dropoff.geometry.location.lat(),
          lng: dropoff.geometry.location.lng(),
        },
      ],
      travelMode: google.maps.TravelMode.DRIVING,
    };

    this.distanceService.getDistanceMatrix(request, (response, status) => {
      if (status === "OK" && response.rows[0].elements[0].status === "OK") {
        const result = response.rows[0].elements[0];

        // Store distance and duration in hidden fields
        this.ensureHiddenField(
          "distance_km",
          (result.distance.value / 1000).toFixed(2)
        );
        this.ensureHiddenField(
          "estimated_duration_minutes",
          Math.round(result.duration.value / 60)
        );
        this.ensureHiddenField(
          "total_travel_duration_minutes",
          Math.round(result.duration.value / 60)
        );
      }
    });
  }

  formatAddress(addressComponents) {
    const componentForm = {
      street_number: 'short_name',
      route: 'long_name',
      sublocality_level_1: 'long_name',
      locality: 'long_name',
      administrative_area_level_1: 'long_name',
      country: 'long_name'
    };

    let formattedAddress = [];
    
    // Build address from components
    const street = [
      this.getAddressComponent(addressComponents, 'street_number'),
      this.getAddressComponent(addressComponents, 'route')
    ].filter(Boolean).join(' ');
    
    const district = this.getAddressComponent(addressComponents, 'sublocality_level_1');
    const city = this.getAddressComponent(addressComponents, 'locality');
    const state = this.getAddressComponent(addressComponents, 'administrative_area_level_1');
    
    if (street) formattedAddress.push(street);
    if (district) formattedAddress.push(district);
    if (city) formattedAddress.push(city);
    if (state) formattedAddress.push(state);
    
    return formattedAddress.join(', ');
  }

  getAddressComponent(components, type) {
    const component = components.find(
      component => component.types[0] === type
    );
    return component ? component.long_name : '';
  }

  getApiKey() {
    const metaTag = document.querySelector('meta[name="google-maps-api-key"]');
    return metaTag ? metaTag.content : null;
  }
}
