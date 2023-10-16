import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "payloadDiv",
     ]

    static values = {
        langCopied: String,
     }

    miniCopyToClipboard(event) {
        if (this.hasPayloadDivTarget) {
            navigator.clipboard.writeText(this.payloadDivTarget.value)
        }

        let button = event.target
        if (button.tagName == 'BUTTON') {
            button = button.querySelector('em')
        }

        button.classList.remove('bi-clipboard-check')
        button.classList.add('bi-check-lg')

        setTimeout(function() {
            button.classList.remove('bi-check-lg')
            button.classList.add('bi-clipboard-check')
        }, 1000)

    }

    copyToClipboard(event) {
        if (this.hasPayloadDivTarget) {
            navigator.clipboard.writeText(this.payloadDivTarget.textContent)
        }
        let button = event.target
        let originalContent = button.innerHTML
        button.innerText = this.langCopiedValue
        setTimeout(function() {
            button.innerHTML = originalContent
        }, 1000)

    }
}
