import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = {
    durationSeconds: Number,
    durationMinutes: { type: Number, default: 5 },
    expiredLabel: { type: String, default: "Expired" }
  }

  connect() {
    const durationMs = this.hasDurationSecondsValue
      ? this.durationSecondsValue * 1000
      : this.durationMinutesValue * 60 * 1000
    this.endTime = Date.now() + durationMs
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
      const totalSeconds = Math.floor(timeRemaining / 1000)
      const minutes = Math.floor(totalSeconds / 60)
      const seconds = totalSeconds % 60
      const padded = seconds.toString().padStart(2, "0")
      this.outputTarget.textContent = `${minutes}:${padded}`
    }
  }
}
