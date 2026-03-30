import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menuButtonInner", "field", "menu", "trigger"]

  connect() {
    this.open = false
  }

  toggle(event) {
    event.stopPropagation()
    this.open ? this.hide() : this.show()
  }

  show() {
    this.open = true
    this.menuTarget.classList.add("show")
    this.positionMenu()
  }

  hide() {
    if (!this.open) return
    this.open = false
    this.menuTarget.classList.remove("show")
    this.menuTarget.style.removeProperty("bottom")
    this.menuTarget.style.removeProperty("top")
  }

  positionMenu() {
    const trigger = this.hasTriggerTarget ? this.triggerTarget : this.element.querySelector("button")
    const menu = this.menuTarget
    const triggerRect = trigger.getBoundingClientRect()
    const menuHeight = menu.offsetHeight
    const spaceBelow = window.innerHeight - triggerRect.bottom
    const spaceAbove = triggerRect.top

    if (spaceBelow < menuHeight && spaceAbove > spaceBelow) {
      menu.style.bottom = "100%"
      menu.style.top = "auto"
    } else {
      menu.style.top = "100%"
      menu.style.bottom = "auto"
    }
  }

  select(event) {
    if (this.hasFieldTarget) {
      this.fieldTarget.value = event.currentTarget.dataset.lang
    }
    const label = event.currentTarget.querySelector("[data-pwpush--select-dropdown-label]")
    if (label) {
      this.menuButtonInnerTarget.innerHTML = label.innerHTML
    }
    this.hide()
  }
}
