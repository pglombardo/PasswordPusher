import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = {
    durationMinutes: { type: Number, default: 5 },
    expiredLabel: { type: String, default: "Expired" }
  }

  connect() {
    this.endTime = Date.now() + this.durationMinutesValue * 60 * 1000
    this.intervalId = setInterval(() => this.tick(), 1000)
    this.tick()
  }

  disconnect() {
    if (this.intervalId) clearInterval(this.intervalId)
  }

  tick() {
    const now = Date.now()
    const timeRemaining = this.endTime - now

    if (timeRemaining < 0) {
      clearInterval(this.intervalId)
      this.intervalId = null
      this.outputTarget.textContent = this.expiredLabelValue
    } else {
      const minutes = Math.floor((timeRemaining % (1000 * 60 * 60)) / (1000 * 60))
      const seconds = Math.floor((timeRemaining % (1000 * 60)) / 1000)
      const padded = seconds.toString().padStart(2, "0")
      this.outputTarget.textContent = `${minutes}:${padded}`
    }
  }
}
