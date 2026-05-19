import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "payloadDiv",
        "icon",
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

        const button = event.currentTarget
        this.clearStrayIconClasses(button)

        const icon = this.iconElement(button)
        if (!icon) return

        if (this.feedbackTimeout) {
            clearTimeout(this.feedbackTimeout)
        }

        this.showCopySuccess(icon)

        this.feedbackTimeout = setTimeout(() => {
            this.resetCopyIcon(icon)
            this.feedbackTimeout = null
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

    disconnect() {
        if (this.feedbackTimeout) {
            clearTimeout(this.feedbackTimeout)
        }
    }

    iconElement(button) {
        if (this.hasIconTarget && button.contains(this.iconTarget)) {
            return this.iconTarget
        }

        return button.querySelector("em")
    }

    showCopySuccess(icon) {
        icon.classList.remove("bi-clipboard-check")
        icon.classList.add("bi-check-lg")
    }

    resetCopyIcon(icon) {
        icon.classList.remove("bi-check-lg")
        icon.classList.add("bi-clipboard-check")
    }

    clearStrayIconClasses(button) {
        const iconClasses = ["bi", "bi-clipboard-check", "bi-check-lg"]

        button.querySelectorAll("span").forEach((element) => {
            iconClasses.forEach((iconClass) => element.classList.remove(iconClass))
        })
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
