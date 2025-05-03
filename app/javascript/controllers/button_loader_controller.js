import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner"]
  
  connect() {
    console.log("Button loader controller connected", this.element)
    
    // Store original disable-with value if exists
    if (this.element.hasAttribute("data-disable-with")) {
      this.originalDisableWith = this.element.getAttribute("data-disable-with")
      // Remove the default Rails disable-with behavior to avoid conflicts
      this.element.removeAttribute("data-disable-with")
    }
    
    // Use the turbo events to show/hide loader
    this.element.addEventListener("click", this.handleClick.bind(this))
    
    // Event listeners for Turbo form submissions
    document.addEventListener("turbo:submit-start", this.handleTurboSubmitStart.bind(this))
    document.addEventListener("turbo:submit-end", this.handleTurboSubmitEnd.bind(this))
    document.addEventListener("turbo:before-fetch-request", this.handleTurboFetchRequest.bind(this))
    document.addEventListener("turbo:before-fetch-response", this.handleTurboFetchResponse.bind(this))
    
    // Fallback for non-Turbo form submissions
    if (this.isFormButton() && this.element.form) {
      console.log("Adding form submit listener to", this.element.form)
      this.element.form.addEventListener("submit", this.handleFormSubmit.bind(this))
    }
    
    // Add handler for network errors
    window.addEventListener("error", this.handleError.bind(this))
  }
  
  disconnect() {
    console.log("Button loader controller disconnected", this.element)
    
    // Restore original disable-with value if it existed
    if (this.originalDisableWith) {
      this.element.setAttribute("data-disable-with", this.originalDisableWith)
    }
    
    // Clean up event listeners
    this.element.removeEventListener("click", this.handleClick.bind(this))
    document.removeEventListener("turbo:submit-start", this.handleTurboSubmitStart.bind(this))
    document.removeEventListener("turbo:submit-end", this.handleTurboSubmitEnd.bind(this))
    document.removeEventListener("turbo:before-fetch-request", this.handleTurboFetchRequest.bind(this))
    document.removeEventListener("turbo:before-fetch-response", this.handleTurboFetchResponse.bind(this))
    
    if (this.isFormButton() && this.element.form) {
      this.element.form.removeEventListener("submit", this.handleFormSubmit.bind(this))
    }
    
    window.removeEventListener("error", this.handleError.bind(this))
  }
  
  // Handle initial button click
  handleClick(event) {
    console.log("Button clicked", event)
    
    // For non-Turbo forms, directly handle the click event
    if (this.isFormButton() && this.element.form && this.element.form.getAttribute("data-turbo") === "false") {
      console.log("Non-Turbo form detected")
      this.showLoader()
      
      // Add a page unload handler to ensure we reset button state if navigating away
      window.addEventListener("beforeunload", this.handleBeforeUnload.bind(this), { once: true })
      
      // Don't disable the button for non-Turbo forms, let the browser handle it
      this.element.disabled = false
      
      // Ensure button is re-enabled if form submission wasn't received
      this.loadingTimeout = setTimeout(() => {
        console.log("Failsafe timeout triggered")
        this.hideLoader()
      }, 10000)
      
      return true // Allow the form to submit normally
    }
    
    // For all other cases, use the standard behavior
    // But don't disable buttons on regular link/button clicks unless form-related
    if (this.isFormButton() || this.element.tagName === "A") {
      this.showLoader()
    }
  }
  
  // Handle page unload for form submission
  handleBeforeUnload(event) {
    console.log("Page unloading")
    window.removeEventListener("beforeunload", this.handleBeforeUnload)
    clearTimeout(this.loadingTimeout)
  }
  
  showLoader() {
    console.log("showLoader called for", this.element)
    // Only add loader if this is a form submission or link button
    if (this.isFormButton() || this.element.tagName === "A" || this.element.tagName === "BUTTON") {
      console.log("Adding loading class to", this.element)
      this.element.classList.add("loading")
      
      // If there's a specific spinner target, show it
      if (this.hasSpinnerTarget) {
        this.spinnerTarget.classList.remove("hidden")
      }
      
      // For AJAX and Turbo forms, disable the button
      // For regular form submissions, don't disable to allow the form to submit
      if (!this.isRegularFormSubmit()) {
        // Disable the button while loading, but store its previous state
        this.wasDisabled = this.element.disabled
        this.element.disabled = true
        console.log("Button disabled", this.element)
      }
      
      // Make sure we re-enable after a timeout as a failsafe
      if (this.loadingTimeout) {
        clearTimeout(this.loadingTimeout)
      }
      
      this.loadingTimeout = setTimeout(() => {
        console.log("Failsafe timeout triggered")
        this.hideLoader()
      }, 10000) // 10 second failsafe timeout
    }
  }
  
  isRegularFormSubmit() {
    return this.isFormButton() && 
           this.element.form && 
           this.element.form.getAttribute("data-turbo") === "false"
  }
  
  hideLoader() {
    console.log("hideLoader called for", this.element)
    // Clear any pending timeout
    if (this.loadingTimeout) {
      clearTimeout(this.loadingTimeout)
      this.loadingTimeout = null
    }
    
    this.element.classList.remove("loading")
    
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }
    
    // Re-enable the button only if it wasn't disabled before
    if (!this.wasDisabled) {
      console.log("Re-enabling button", this.element)
      this.element.disabled = false
    }
  }
  
  isFormButton() {
    const result = (this.element.tagName === "BUTTON" && 
           (this.element.type === "submit" || !this.element.type)) || 
           (this.element.tagName === "INPUT" && this.element.type === "submit")
    if (result) {
      console.log("Element is a form button", this.element)
    }
    return result
  }
  
  // Handle traditional form submission
  handleFormSubmit(event) {
    console.log("Form submit event", event)
    // Always show loader on form submit
    this.showLoader()
  }
  
  // Handle turbo:submit-start event
  handleTurboSubmitStart(event) {
    console.log("turbo:submit-start", event)
    // Only respond if the event is from our button's form
    if (this.isRelatedToThisButton(event.target)) {
      console.log("Related to this button", this.element)
      this.showLoader()
    }
  }
  
  // Handle turbo:submit-end event
  handleTurboSubmitEnd(event) {
    console.log("turbo:submit-end", event)
    // Only respond if the event is from our button's form
    if (this.isRelatedToThisButton(event.target)) {
      console.log("Related to this button", this.element)
      this.hideLoader()
    }
  }
  
  // Handle turbo:before-fetch-request event
  handleTurboFetchRequest(event) {
    console.log("turbo:before-fetch-request", event)
    // For link buttons or direct Turbo requests
    if (this.isRelatedToThisButton(event.target)) {
      console.log("Related to this button", this.element)
      this.showLoader()
    }
  }
  
  // Handle turbo:before-fetch-response event
  handleTurboFetchResponse(event) {
    console.log("turbo:before-fetch-response", event)
    // For link buttons or direct Turbo requests
    if (this.isRelatedToThisButton(event.target)) {
      console.log("Related to this button", this.element)
      this.hideLoader()
    }
  }
  
  // Error handler to ensure button gets re-enabled
  handleError(event) {
    console.log("Error event", event)
    this.hideLoader()
  }
  
  isRelatedToThisButton(targetElement) {
    // Check if the event target is the button or its form
    const result = (
      this.element === targetElement ||
      (this.element.form && this.element.form === targetElement) ||
      this.element.contains(targetElement) ||
      (this.element.parentElement && this.element.parentElement.contains(targetElement))
    )
    console.log("isRelatedToThisButton", result, this.element, targetElement)
    return result
  }
} 