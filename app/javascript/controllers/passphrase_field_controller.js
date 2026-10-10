import { Controller } from "@hotwired/stimulus"
import Cookies from "js-cookie"

export default class extends Controller {
    static targets = ["input", "copyButton", "copyIcon", "clearButton", "generateButton", "error"]

    static values = {
        generateUrl: String,
        languageDefault: String,
        wordCountDefault: Number,
        separatorDefault: String,
        capitalizeDefault: Boolean,
        numberDefault: Boolean,
        symbolDefault: Boolean,
        failed: String
    }

    connect() {
        this.generationInFlight = false
        this.syncButtons()
    }

    disconnect() {
        if (this.copyFeedbackTimeout) {
            clearTimeout(this.copyFeedbackTimeout)
        }
    }

    changed() {
        this.syncButtons()
    }

    clear(event) {
        event?.preventDefault()

        if (this.generationInFlight || this.inputDisabled()) {
            return
        }

        this.inputTarget.value = ""
        this.clearError()
        this.syncButtons()
        this.inputTarget.focus()
    }

    async copy(event) {
        event?.preventDefault()

        const text = this.hasInputTarget ? this.inputTarget.value : ""
        if (!text) {
            return
        }

        try {
            if (navigator.clipboard && navigator.clipboard.writeText) {
                await navigator.clipboard.writeText(text)
            } else {
                this.fallbackCopy(text)
            }
        } catch (error) {
            this.fallbackCopy(text)
        }

        this.flashCopied()
    }

    async generate(event) {
        event?.preventDefault()

        if (this.generationInFlight || this.inputDisabled()) {
            return
        }

        const result = await this.requestGeneration(this.passphraseConfig())
        if (!result) {
            return
        }

        if (result.error) {
            this.showError(result.error)
            return
        }

        this.clearError()
        this.inputTarget.value = result.results[0]
        this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
        this.syncButtons()
        if (this.hasGenerateButtonTarget) {
            this.generateButtonTarget.blur()
        }
    }

    passphraseConfig() {
        const config = {
            language: this.languageDefaultValue,
            wordCount: this.wordCountDefaultValue,
            separator: this.separatorDefaultValue,
            capitalize: this.capitalizeDefaultValue,
            number: this.numberDefaultValue,
            symbol: this.symbolDefaultValue
        }

        this.readCookie("pwgen_language", (value) => { config.language = value })
        this.readCookie("pwgen_wordCount", (value) => { config.wordCount = parseInt(value, 10) })
        this.readCookie("pwgen_separator", (value) => { config.separator = value })
        this.readCookie("pwgen_capitalize", (value) => { config.capitalize = this.toBoolean(value) })
        this.readCookie("pwgen_number", (value) => { config.number = this.toBoolean(value) })
        this.readCookie("pwgen_symbol", (value) => { config.symbol = this.toBoolean(value) })

        return config
    }

    readCookie(name, assign) {
        const value = Cookies.get(name)
        if (typeof value === "string") {
            assign(value)
        }
    }

    toBoolean(candidate) {
        if (typeof candidate === "string") {
            return candidate === "true"
        }
        if (typeof candidate === "boolean") {
            return candidate
        }
        return false
    }

    async requestGeneration(config) {
        if (this.generationInFlight) {
            return null
        }

        this.generationInFlight = true
        this.setGenerateBusy(true)

        try {
            const response = await fetch(this.generateUrlValue, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Accept: "application/json"
                },
                body: JSON.stringify({
                    type: "passphrase",
                    count: 1,
                    language: config.language,
                    word_count: config.wordCount,
                    separator: config.separator,
                    capitalize: config.capitalize,
                    number: config.number,
                    symbol: config.symbol
                })
            })
            const body = await this.parseJsonBody(response)
            if (!response.ok || !body?.results?.[0]) {
                return { error: body?.error || this.failedMessage() }
            }
            return body
        } catch (error) {
            return { error: this.failedMessage() }
        } finally {
            this.generationInFlight = false
            this.setGenerateBusy(false)
        }
    }

    async parseJsonBody(response) {
        try {
            return await response.json()
        } catch (error) {
            return null
        }
    }

    failedMessage() {
        return this.failedValue || "Password generation failed."
    }

    setGenerateBusy(busy) {
        if (this.hasGenerateButtonTarget) {
            this.generateButtonTarget.disabled = busy
        }
    }

    syncButtons() {
        if (!this.hasInputTarget) {
            return
        }

        const hasValue = this.inputTarget.value.length > 0
        if (this.hasCopyButtonTarget) {
            this.copyButtonTarget.hidden = !hasValue
        }
        if (this.hasClearButtonTarget) {
            this.clearButtonTarget.hidden = !hasValue
        }
    }

    showError(message) {
        if (!this.hasErrorTarget) {
            return
        }

        this.errorTarget.textContent = message
        this.errorTarget.hidden = false
    }

    clearError() {
        if (!this.hasErrorTarget) {
            return
        }

        this.errorTarget.textContent = ""
        this.errorTarget.hidden = true
    }

    flashCopied() {
        if (!this.hasCopyIconTarget) {
            return
        }

        const icon = this.copyIconTarget
        icon.classList.remove("bi-clipboard")
        icon.classList.add("bi-check-lg")

        if (this.copyFeedbackTimeout) {
            clearTimeout(this.copyFeedbackTimeout)
        }

        this.copyFeedbackTimeout = setTimeout(() => {
            icon.classList.remove("bi-check-lg")
            icon.classList.add("bi-clipboard")
            this.copyFeedbackTimeout = null
        }, 1000)
    }

    fallbackCopy(text) {
        const textArea = document.createElement("textarea")
        textArea.value = text
        textArea.style.position = "fixed"
        textArea.style.left = "-999999px"
        textArea.style.top = "-999999px"
        document.body.appendChild(textArea)
        textArea.focus()
        textArea.select()
        try {
            document.execCommand("copy")
        } catch (error) {
            console.error("Fallback: Oops, unable to copy", error)
        }
        document.body.removeChild(textArea)
    }

    inputDisabled() {
        return !this.hasInputTarget || this.inputTarget.disabled
    }
}
