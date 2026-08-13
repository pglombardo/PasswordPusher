import { Controller } from "@hotwired/stimulus"

// Light / dark / system theme control via Bootstrap data-bs-theme.
//
// Instance lock (data-theme-instance-mode-value):
//   light | dark — force that mode; ignore localStorage and OS
//   auto         — follow localStorage.theme, else OS preference
//
// When auto, cycle() rotates: light → dark → system → light …
// Preference is stored in localStorage.theme (anonymous-safe).

export default class extends Controller {
  static values = {
    instanceMode: { type: String, default: "auto" },
    labelLight: { type: String, default: "Use light theme" },
    labelDark: { type: String, default: "Use dark theme" },
    labelSystem: { type: String, default: "Use system theme" }
  }

  static targets = ["icon", "button"]

  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.boundOnSystemChange = this.onSystemChange.bind(this)
    this.sessionPreference = null

    this.apply()

    if (this.isAuto) {
      this.mediaQuery.addEventListener("change", this.boundOnSystemChange)
    }
  }

  disconnect() {
    if (this.mediaQuery && this.boundOnSystemChange) {
      this.mediaQuery.removeEventListener("change", this.boundOnSystemChange)
    }
  }

  get isAuto() {
    return this.instanceModeValue === "auto"
  }

  get storedPreference() {
    try {
      const value = localStorage.getItem("theme")
      if (value === "light" || value === "dark" || value === "system") {
        return value
      }
    } catch (_error) {
      // Privacy modes / disabled storage — fall through
    }

    if (this.sessionPreference === "light" || this.sessionPreference === "dark" || this.sessionPreference === "system") {
      return this.sessionPreference
    }

    return "system"
  }

  get systemPrefersDark() {
    return this.mediaQuery.matches
  }

  resolveMode() {
    if (!this.isAuto) {
      return this.instanceModeValue === "dark" ? "dark" : "light"
    }

    const preference = this.storedPreference
    if (preference === "light" || preference === "dark") {
      return preference
    }
    return this.systemPrefersDark ? "dark" : "light"
  }

  apply() {
    const mode = this.resolveMode()
    document.documentElement.setAttribute("data-bs-theme", mode)
    this.updateButton(mode)
  }

  onSystemChange() {
    if (this.isAuto && this.storedPreference === "system") {
      this.apply()
    }
  }

  cycle(event) {
    if (event) {
      event.preventDefault()
    }
    if (!this.isAuto) {
      return
    }

    const order = ["light", "dark", "system"]
    const current = this.storedPreference
    const next = order[(order.indexOf(current) + 1) % order.length]
    this.sessionPreference = next

    try {
      localStorage.setItem("theme", next)
    } catch (_error) {
      // Keep sessionPreference so the toggle still works without storage
    }

    this.apply()
  }

  updateButton(resolvedMode) {
    if (!this.hasButtonTarget) {
      return
    }

    const preference = this.isAuto ? this.storedPreference : this.instanceModeValue
    let iconClass = "bi-circle-half"
    let label = this.labelSystemValue

    if (preference === "light") {
      iconClass = "bi-moon"
      label = this.labelDarkValue
    } else if (preference === "dark") {
      iconClass = "bi-sun"
      label = this.labelLightValue
    }

    this.buttonTarget.setAttribute("title", label)
    this.buttonTarget.setAttribute("aria-label", label)

    if (this.hasIconTarget) {
      this.iconTarget.className = `bi ${iconClass}`
    }

    this.buttonTarget.dataset.themePreference = preference
    this.buttonTarget.dataset.themeResolved = resolvedMode
  }
}
