import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    this.prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)")
    
    // Initial check
    this.handleThemeChange(this.prefersDarkScheme)
    
    // Listen for changes
    this.prefersDarkScheme.addEventListener('change', this.handleThemeChange.bind(this))
  }

  disconnect() {
    // Clean up event listener when controller disconnects
    this.prefersDarkScheme.removeEventListener('change', this.handleThemeChange.bind(this))
  }

  handleThemeChange(e) {
    if (e.matches) {
      document.documentElement.setAttribute('data-bs-theme', 'dark')
    } else {
      document.documentElement.setAttribute('data-bs-theme', 'light')
    }
  }
} 