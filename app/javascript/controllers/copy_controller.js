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
            const text = this.payloadDivTarget.value
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).catch(() => {
                    this.fallbackCopyToClipboard(text)
                })
            } else {
                this.fallbackCopyToClipboard(text)
            }
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
            const text = this.payloadDivTarget.textContent
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).catch(() => {
                    this.fallbackCopyToClipboard(text)
                })
            } else {
                this.fallbackCopyToClipboard(text)
            }
        }
        let button = event.target
        let originalContent = button.innerHTML
        button.innerText = this.langCopiedValue
        setTimeout(function() {
            button.innerHTML = originalContent
        }, 1000)

    }

    fallbackCopyToClipboard(text) {
        const textArea = document.createElement('textarea')
        textArea.value = text
        textArea.style.position = 'fixed'
        textArea.style.left = '-999999px'
        textArea.style.top = '-999999px'
        document.body.appendChild(textArea)
        textArea.focus()
        textArea.select()
        try {
            document.execCommand('copy')
        } catch (err) {
            console.error('Fallback: Oops, unable to copy', err)
        }
        document.body.removeChild(textArea)
    }
}
