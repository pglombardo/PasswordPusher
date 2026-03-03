import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "pushit",
    ]

    static values = {
    }

    connect() {
        this._uploadInProgress = false
        this._disabledByUpload = false
        this._boundUploading = this._onUploading.bind(this)
        this._boundIdle = this._onIdle.bind(this)
        this.element.addEventListener("multi-upload:uploading", this._boundUploading)
        this.element.addEventListener("multi-upload:idle", this._boundIdle)
    }

    disconnect() {
        this.element.removeEventListener("multi-upload:uploading", this._boundUploading)
        this.element.removeEventListener("multi-upload:idle", this._boundIdle)
    }

    _onUploading() {
        this._uploadInProgress = true
        if (this.hasPushitTarget) {
            this._disabledByUpload = true
            this.pushitTarget.disabled = true
            this.pushitTarget.setAttribute("aria-busy", "true")
        }
    }

    _onIdle() {
        this._uploadInProgress = false
        if (this.hasPushitTarget && this._disabledByUpload) {
            this._disabledByUpload = false
            this.pushitTarget.disabled = false
            this.pushitTarget.removeAttribute("aria-busy")
        }
    }

    disableWith(event) {
        let disableText = event.target.getAttribute('data-disable-with')

        if (disableText === null) {
            disableText = 'Processing...'
        }

        if (event.target.tagName == 'INPUT') {
            event.target.value = disableText
        } else {
            event.target.innerText = disableText
        }
        event.target.disabled = true
    }

    submit(event) {
        // Block submit while uploads are in progress even if button was re-enabled via DOM
        if (this._uploadInProgress) {
            event.preventDefault()
            event.stopPropagation()
            return
        }
        let submitButton = this.pushitTarget
        let disableText = submitButton.getAttribute("data-disable-with")

        if (disableText === null) {
            disableText = "Processing..."
        }

        if (submitButton.tagName === "INPUT") {
            submitButton.value = disableText
        } else {
            submitButton.innerText = disableText
        }
        submitButton.disabled = true
    }
}
