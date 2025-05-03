import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner"]
  
  connect() {
    // Use the turbo events to show/hide loader
    this.element.addEventListener("click", this.showLoader.bind(this))
    document.addEventListener("turbo:submit-start", this.handleTurboSubmitStart.bind(this))
    document.addEventListener("turbo:submit-end", this.handleTurboSubmitEnd.bind(this))
    document.addEventListener("turbo:before-fetch-request", this.handleTurboFetchRequest.bind(this))
    document.addEventListener("turbo:before-fetch-response", this.handleTurboFetchResponse.bind(this))
  }
  
  disconnect() {
    this.element.removeEventListener("click", this.showLoader.bind(this))
    document.removeEventListener("turbo:submit-start", this.handleTurboSubmitStart.bind(this))
    document.removeEventListener("turbo:submit-end", this.handleTurboSubmitEnd.bind(this))
    document.removeEventListener("turbo:before-fetch-request", this.handleTurboFetchRequest.bind(this))
    document.removeEventListener("turbo:before-fetch-response", this.handleTurboFetchResponse.bind(this))
  }
  
  showLoader(event) {
    // Only add loader if this is a form submission
    if (this.isFormButton()) {
      this.element.classList.add("loading")
      
      // If there's a specific spinner target, show it
      if (this.hasSpinnerTarget) {
        this.spinnerTarget.classList.remove("hidden")
      }
      
      // Disable the button while loading
      this.element.disabled = true
    }
  }
  
  hideLoader() {
    this.element.classList.remove("loading")
    
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }
    
    // Re-enable the button
    this.element.disabled = false
  }
  
  isFormButton() {
    return this.element.tagName === "BUTTON" || 
           (this.element.tagName === "INPUT" && this.element.type === "submit")
  }
  
  // Handle turbo:submit-start event
  handleTurboSubmitStart(event) {
    // Only respond if the event is from our button's form
    if (this.isRelatedToThisButton(event.target)) {
      this.showLoader()
    }
  }
  
  // Handle turbo:submit-end event
  handleTurboSubmitEnd(event) {
    // Only respond if the event is from our button's form
    if (this.isRelatedToThisButton(event.target)) {
      this.hideLoader()
    }
  }
  
  // Handle turbo:before-fetch-request event
  handleTurboFetchRequest(event) {
    // For link buttons or direct Turbo requests
    if (this.isRelatedToThisButton(event.target)) {
      this.showLoader()
    }
  }
  
  // Handle turbo:before-fetch-response event
  handleTurboFetchResponse(event) {
    // For link buttons or direct Turbo requests
    if (this.isRelatedToThisButton(event.target)) {
      this.hideLoader()
    }
  }
  
  isRelatedToThisButton(targetElement) {
    // Check if the event target is the button or its form
    return (
      this.element === targetElement ||
      (this.element.form && this.element.form === targetElement) ||
      this.element.contains(targetElement)
    )
  }
} 