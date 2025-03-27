import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "bar", "cancelButton", "timeoutMessage"]
  static values = { 
    id: String,
    seconds: Number 
  }
  
  connect() {
    this.setupTimer()
  }
  
  disconnect() {
    this.stopTimer()
  }
  
  setupTimer() {
    // Check if we have a stored timer value for this ride
    const savedTimeKey = `timer_ride_${this.idValue}`
    const savedEndTimeKey = `timer_end_ride_${this.idValue}`
    
    const savedEndTime = localStorage.getItem(savedEndTimeKey)
    const now = new Date().getTime()
    
    // If we have a saved end time, calculate remaining time
    if (savedEndTime) {
      const endTime = parseInt(savedEndTime)
      const timeLeft = Math.max(0, Math.floor((endTime - now) / 1000))
      
      // If timer already expired
      if (timeLeft <= 0) {
        this.timeLeft = 0
        this.handleTimerExpired()
        return
      } else {
        this.timeLeft = timeLeft
      }
    } else {
      // Start a new timer
      this.timeLeft = this.secondsValue
      
      // Save the expected end time
      const endTime = now + (this.timeLeft * 1000)
      localStorage.setItem(savedEndTimeKey, endTime.toString())
    }
    
    this.startTimer()
  }
  
  startTimer() {
    this.updateDisplay()
    
    this.interval = setInterval(() => {
      this.timeLeft -= 1
      
      // Save the current time left
      const savedTimeKey = `timer_ride_${this.idValue}`
      localStorage.setItem(savedTimeKey, this.timeLeft.toString())
      
      if (this.timeLeft <= 0) {
        this.stopTimer()
        this.handleTimerExpired()
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
  
  handleTimerExpired() {
    this.displayTarget.textContent = "0:00"
    this.barTarget.style.width = "0%"
    
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.disabled = false
      this.cancelButtonTarget.classList.remove('bg-gray-400', 'cursor-not-allowed')
      this.cancelButtonTarget.classList.add('bg-red-600', 'hover:bg-red-500')
    }
    
    if (this.hasTimeoutMessageTarget) {
      this.timeoutMessageTarget.classList.remove('hidden')
    }
  }
  
  // Reset timer data
  resetTimer() {
    const savedTimeKey = `timer_ride_${this.idValue}`
    const savedEndTimeKey = `timer_end_ride_${this.idValue}`
    
    localStorage.removeItem(savedTimeKey)
    localStorage.removeItem(savedEndTimeKey)
  }
} 