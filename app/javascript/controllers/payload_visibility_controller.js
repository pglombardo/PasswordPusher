import { Controller } from "@hotwired/stimulus"

// Masks the push payload textarea while typing (eye toggle).
// Preference is stored in localStorage.pwpush_payload_hidden (anonymous-safe).
export default class extends Controller {
  static targets = ["input", "toggle", "showIcon", "hideIcon"]

  static values = {
    hideLabel: { type: String, default: "Hide payload" },
    showLabel: { type: String, default: "Show payload" }
  }

  static STORAGE_KEY = "pwpush_payload_hidden"

  connect() {
    this.apply(this.storedHidden)
  }

  toggle(event) {
    event.preventDefault()
    this.apply(!this.isHidden)
  }

  get isHidden() {
    return this.inputTarget.classList.contains("payload-hidden")
  }

  get storedHidden() {
    try {
      return localStorage.getItem(this.constructor.STORAGE_KEY) === "true"
    } catch (_error) {
      return false
    }
  }

  apply(hidden) {
    this.inputTarget.classList.toggle("payload-hidden", hidden)

    if (this.hasShowIconTarget) {
      this.showIconTarget.classList.toggle("d-none", hidden)
    }
    if (this.hasHideIconTarget) {
      this.hideIconTarget.classList.toggle("d-none", !hidden)
    }

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-pressed", hidden ? "true" : "false")
      this.toggleTarget.setAttribute(
        "aria-label",
        hidden ? this.showLabelValue : this.hideLabelValue
      )
      this.toggleTarget.setAttribute(
        "title",
        hidden ? this.showLabelValue : this.hideLabelValue
      )
    }

    try {
      localStorage.setItem(this.constructor.STORAGE_KEY, hidden ? "true" : "false")
    } catch (_error) {
      // Ignore private-mode / disabled storage
    }
  }
}
