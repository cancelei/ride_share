import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []
  
  connect() {    
    this.element.addEventListener("click", this.handleClick.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("click", this.handleClick.bind(this))
  }

  // Handle initial button click
  handleClick(event) {
    const loader = document.createElement("span");
    loader.classList.add("loader");
    loader.style.display = "inline-block";
    loader.style.marginLeft = "10px";
    this.element.style.width = window.getComputedStyle(this.element).width;

    let dotCount = 0;
    const interval = setInterval(() => {
      dotCount = (dotCount % 3) + 1;
      const dots = ".".repeat(dotCount);

      if (this.element.tagName === "INPUT") {
        this.element.value = dots;
      } else {
        this.element.innerText = dots;
      }
    }, 500);

    if (this.element.tagName === "INPUT") {
      loader.style.position = "relative";
      loader.style.left = "-34px";
      loader.style.top = "10px";
      this.element.style.paddingRight = "30px";
      this.element.value = "...";
      this.element.insertAdjacentElement("afterend", loader);
    } else {
      this.element.style.position = "relative";
      loader.style.position = "absolute";
      loader.style.right = "10px";
      loader.style.top = "50%";
      loader.style.transform = "translateY(-50%)";
      this.element.innerText = "...";
      this.element.appendChild(loader);
    }
  }
} 