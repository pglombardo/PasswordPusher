import { Controller } from "@hotwired/stimulus"
import { Dropdown } from "bootstrap"

export default class extends Controller {
  static targets = ["hiddenInput", "trigger", "triggerGlobe", "triggerFlag", "triggerLabel"]

  choose(event) {
    const option = event.currentTarget
    const value = option.dataset.localeValue ?? ""
    const label = option.dataset.localeLabel ?? ""
    const flagClass = option.dataset.localeFlagClass ?? ""
    const isAutodetect = value === ""

    this.hiddenInputTarget.value = value
    this.triggerLabelTarget.textContent = isAutodetect ? "" : label

    if (this.hasTriggerGlobeTarget) {
      this.triggerGlobeTarget.style.display = isAutodetect ? "" : "none"
    }
    if (this.hasTriggerFlagTarget) {
      this.triggerFlagTarget.className = flagClass ? `fi fi-${flagClass}` : ""
      this.triggerFlagTarget.style.display = isAutodetect ? "none" : ""
    }

    Dropdown.getOrCreateInstance(this.triggerTarget).hide()
  }
}
