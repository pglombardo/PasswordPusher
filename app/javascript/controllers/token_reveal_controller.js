import { Controller } from "@hotwired/stimulus"

// Revealed API tokens must not survive bfcache / native Back.
export default class extends Controller {
  static values = { maskedUrl: String }

  initialize() {
    this.onPageHide = this.onPageHide.bind(this)
    this.onPageShow = this.onPageShow.bind(this)
  }

  connect() {
    window.addEventListener("pagehide", this.onPageHide)
    window.addEventListener("pageshow", this.onPageShow)
  }

  disconnect() {
    window.removeEventListener("pagehide", this.onPageHide)
    window.removeEventListener("pageshow", this.onPageShow)
  }

  onPageHide() {
    const tokenEl = this.element.querySelector("#authentication_token")
    if (tokenEl) tokenEl.replaceChildren()
  }

  onPageShow(event) {
    if (!event.persisted) return
    if (!this.hasMaskedUrlValue) return

    window.location.replace(this.maskedUrlValue)
  }
}
