import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "bar"]
  static values = { 
    id: String,
    seconds: Number 
  }
  
  connect() {
    this.timeLeft = this.secondsValue
    this.startTimer()
  }
  
  disconnect() {
    this.stopTimer()
  }
  
  startTimer() {
    this.updateDisplay()
    
    this.interval = setInterval(() => {
      this.timeLeft -= 1
      
      if (this.timeLeft <= 0) {
        this.stopTimer()
        this.displayTarget.textContent = "0:00"
        this.barTarget.style.width = "0%"
      } else {
        this.updateDisplay()
      }
    }, 1000)
  }
  
  stopTimer() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }
  
  updateDisplay() {
    const minutes = Math.floor(this.timeLeft / 60)
    const seconds = this.timeLeft % 60
    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
    
    // Update progress bar
    const percentLeft = (this.timeLeft / this.secondsValue) * 100
    this.barTarget.style.width = `${percentLeft}%`
  }
} 