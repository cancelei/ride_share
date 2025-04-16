import { Controller } from "@hotwired/stimulus"

// Manages avatar image upload previews
export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("change", this.previewAvatar.bind(this))
    }
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("change", this.previewAvatar.bind(this))
    }
  }

  previewAvatar(event) {
    const input = event.target
    
    if (input.files && input.files[0]) {
      // Validate file size (5MB max)
      const maxSize = 5 * 1024 * 1024 // 5MB in bytes
      if (input.files[0].size > maxSize) {
        alert("File size exceeds 5MB limit")
        input.value = ""
        return
      }

      // Validate file type
      const fileType = input.files[0].type
      if (!['image/png', 'image/jpeg', 'image/jpg'].includes(fileType)) {
        alert("Only PNG, JPEG or JPG images are allowed")
        input.value = ""
        return
      }

      // Create temporary URL for the selected file
      const url = URL.createObjectURL(input.files[0])
      
      // Find preview container - it's either the explicitly targeted element
      // or the nearest parent with the relevant image/preview
      let previewContainer
      if (this.hasPreviewTarget) {
        previewContainer = this.previewTarget
      } else {
        previewContainer = input.closest(".w-48.h-48")
      }

      if (previewContainer) {
        // Clear the container
        previewContainer.innerHTML = ""
        
        // Create and add the image preview
        const img = document.createElement("img")
        img.src = url
        img.className = "w-full h-full object-cover"
        previewContainer.appendChild(img)
      }
    }
  }
} 