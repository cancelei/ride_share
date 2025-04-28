import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button"];

  connect() {
    // Optional: Initialization logic if needed
  }

  addLoader(event) {
    const button = event.currentTarget;
    button.disabled = true;

    // Create loader element
    const loader = document.createElement("span");
    loader.classList.add("loader");
    loader.style.display = "inline-block";
    loader.style.position = "absolute";
    loader.style.right = "10px";
    loader.style.top = "50%";
    loader.style.transform = "translateY(-50%)";

    // Add loader to the button
    button.style.position = "relative";
    const existingPaddingRight = window.getComputedStyle(button).paddingRight;
    button.style.paddingRight = "30px";
    button.appendChild(loader);

    const form = button.closest("form");
    if (form) {
      form.submit();
    }
    // Simulate async action (e.g., API call)
    setTimeout(() => {
      loader.remove();
      button.style.paddingRight = existingPaddingRight;
      button.disabled = false;
    }, 2000);
  }
}