import { Controller } from "@hotwired/stimulus"

// This controller ensures that vehicle actions, such as editing, only happen on click
export default class extends Controller {
  static targets = ["editLink", "deleteButton"]

  connect() {
    // Disable any potential hover effects by making sure we only react to clicks
    this.editLinkTargets.forEach(link => {
      // Remove any default hover behaviors
      link.addEventListener('mouseenter', this.preventDefaultAction)
      link.addEventListener('mouseover', this.preventDefaultAction)
    })
    
    // Ensure delete buttons have proper confirmation
    this.deleteButtonTargets.forEach(button => {
      button.addEventListener('click', this.confirmDelete)
    })
  }

  disconnect() {
    this.editLinkTargets.forEach(link => {
      link.removeEventListener('mouseenter', this.preventDefaultAction)
      link.removeEventListener('mouseover', this.preventDefaultAction)
    })
    
    this.deleteButtonTargets.forEach(button => {
      button.removeEventListener('click', this.confirmDelete)
    })
  }

  preventDefaultAction(event) {
    // Prevent any default behavior on hover
    event.preventDefault()
    event.stopPropagation()
  }
  
  confirmDelete(event) {
    // The confirmation is now handled by turbo_confirm, but we can add additional logic here if needed
    console.log("Delete button clicked - confirmation handled by Turbo")
  }
} 