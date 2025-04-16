import { Controller } from "@hotwired/stimulus"

// This controller handles automatic removal of elements like flash messages
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 } // Default 5 seconds before auto-removal
  }
  
  connect() {
    // Set a timeout to add the fade-out class after the delay
    this.timeout = setTimeout(() => {
      this.element.classList.add("fade-out")
      
      // Add a backup timeout to remove the element if the animation doesn't trigger
      this.backupTimeout = setTimeout(() => {
        this.element.remove()
      }, 1000) // Wait 1 second after adding fade-out
    }, this.delayValue)
  }
  
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    if (this.backupTimeout) {
      clearTimeout(this.backupTimeout)
    }
  }
  
  remove() {
    // This is triggered by the animationend event
    this.element.remove()
    if (this.backupTimeout) {
      clearTimeout(this.backupTimeout)
    }
  }
} 