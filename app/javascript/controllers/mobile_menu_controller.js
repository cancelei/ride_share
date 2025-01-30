import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Bind the closeMenu method to this controller instance
    this.closeMenuBound = this.closeMenu.bind(this)
    // Add click event listener to document when controller connects
    document.addEventListener("click", this.closeMenuBound)
  }

  disconnect() {
    // Remove click event listener when controller disconnects
    document.removeEventListener("click", this.closeMenuBound)
  }

  toggle(event) {
    // Prevent the click event from bubbling up to document
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  closeMenu(event) {
    // Only close if clicking outside the menu and the menu is open
    if (!this.menuTarget.classList.contains("hidden") && 
        !this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }
} 