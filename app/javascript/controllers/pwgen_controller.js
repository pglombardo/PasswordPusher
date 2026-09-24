import { Controller } from "@hotwired/stimulus"
import Cookies from "js-cookie"
import { Modal } from "bootstrap"

export default class extends Controller {
    static targets = [
        "testPayloadArea",
        "entropyArea",
        "payloadInput",
        "typeInput",
        "languageInput",
        "wordCountInput",
        "separatorInput",
        "capitalizeCheckbox",
        "numberCheckbox",
        "symbolCheckbox",
        "passwordLengthInput",
        "charsetInput",
        "uppercaseCheckbox",
        "lowercaseCheckbox",
        "digitsCheckbox",
        "symbolsCheckbox",
        "avoidAmbiguousCheckbox",
        "pinLengthInput",
        "wordCountDisplay",
        "passwordLengthDisplay",
        "pinLengthDisplay",
        "passphraseFields",
        "passwordFields",
        "pinFields",
        "generateConfirmModal"
    ]

    static values = {
        gaEnabled: Boolean,
        generateUrl: String,
        typeDefault: String,
        languageDefault: String,
        wordCountDefault: Number,
        separatorDefault: String,
        capitalizeDefault: Boolean,
        numberDefault: Boolean,
        symbolDefault: Boolean,
        passwordLengthDefault: Number,
        charsetDefault: String,
        uppercaseDefault: Boolean,
        lowercaseDefault: Boolean,
        digitsDefault: Boolean,
        symbolsDefault: Boolean,
        avoidAmbiguousDefault: Boolean,
        pinLengthDefault: Number,
        wordlistSizes: Object,
        langEntropy: String,
        langFailed: String
    }

    initialize() {
        this.configDefaults = {}
        this.config = {}
        this.isContentGenerated = false
    }

    connect() {
        this.loadSettings()
        this.loadForm()
        this.toggleTypeFields()
        this.syncEstimatedEntropy()
        this.confirmationModal = new Modal(this.generateConfirmModalTarget)
    }

    setContentNotGenerated() {
        this.isContentGenerated = false
    }

    typeChanged() {
        this.toggleTypeFields()
        this.syncEstimatedEntropy()
    }

    toggleTypeFields() {
        const type = this.selectedType()
        this.activatePanel(this.passphraseFieldsTarget, type === "passphrase")
        this.activatePanel(this.passwordFieldsTarget, type === "password")
        this.activatePanel(this.pinFieldsTarget, type === "pin")
    }

    activatePanel(panel, active) {
        panel.classList.toggle("is-active", active)
        panel.toggleAttribute("inert", !active)
        panel.setAttribute("aria-hidden", active ? "false" : "true")
    }

    syncRangeDisplays() {
        if (this.hasWordCountDisplayTarget) {
            this.wordCountDisplayTarget.textContent = this.wordCountInputTarget.value
        }
        if (this.hasPasswordLengthDisplayTarget) {
            this.passwordLengthDisplayTarget.textContent = this.passwordLengthInputTarget.value
        }
        if (this.hasPinLengthDisplayTarget) {
            this.pinLengthDisplayTarget.textContent = this.pinLengthInputTarget.value
        }
        this.syncEstimatedEntropy()
    }

    selectedType() {
        const selected = this.typeInputTargets.find((input) => input.checked)
        return selected ? selected.value : this.config.type
    }

    loadForm() {
        this.typeInputTargets.forEach((input) => {
            input.checked = input.value === this.config.type
        })
        this.languageInputTarget.value = this.config.language
        this.wordCountInputTarget.value = this.config.wordCount
        this.separatorInputTarget.value = this.config.separator
        this.capitalizeCheckboxTarget.checked = this.config.capitalize
        this.numberCheckboxTarget.checked = this.config.number
        this.symbolCheckboxTarget.checked = this.config.symbol
        this.passwordLengthInputTarget.value = this.config.passwordLength
        this.charsetInputTarget.value = this.config.charset
        this.uppercaseCheckboxTarget.checked = this.config.uppercase
        this.lowercaseCheckboxTarget.checked = this.config.lowercase
        this.digitsCheckboxTarget.checked = this.config.digits
        this.symbolsCheckboxTarget.checked = this.config.symbols
        this.avoidAmbiguousCheckboxTarget.checked = this.config.avoidAmbiguous
        this.pinLengthInputTarget.value = this.config.pinLength
        this.syncRangeDisplays()
        this.toggleTypeFields()
    }

    loadSettings() {
        this.configDefaults = {
            type: this.typeDefaultValue,
            language: this.languageDefaultValue,
            wordCount: this.wordCountDefaultValue,
            separator: this.separatorDefaultValue,
            capitalize: this.capitalizeDefaultValue,
            number: this.numberDefaultValue,
            symbol: this.symbolDefaultValue,
            passwordLength: this.passwordLengthDefaultValue,
            charset: this.charsetDefaultValue,
            uppercase: this.uppercaseDefaultValue,
            lowercase: this.lowercaseDefaultValue,
            digits: this.digitsDefaultValue,
            symbols: this.symbolsDefaultValue,
            avoidAmbiguous: this.avoidAmbiguousDefaultValue,
            pinLength: this.pinLengthDefaultValue
        }

        this.config = Object.assign({}, this.configDefaults)

        this.readCookie("pwgen_type", (value) => { this.config.type = value })
        this.readCookie("pwgen_language", (value) => { this.config.language = value })
        this.readCookie("pwgen_wordCount", (value) => { this.config.wordCount = parseInt(value, 10) })
        this.readCookie("pwgen_separator", (value) => { this.config.separator = value })
        this.readCookie("pwgen_capitalize", (value) => { this.config.capitalize = this.toBoolean(value) })
        this.readCookie("pwgen_number", (value) => { this.config.number = this.toBoolean(value) })
        this.readCookie("pwgen_symbol", (value) => { this.config.symbol = this.toBoolean(value) })
        this.readCookie("pwgen_passwordLength", (value) => { this.config.passwordLength = parseInt(value, 10) })
        this.readCookie("pwgen_charset", (value) => { this.config.charset = value })
        this.readCookie("pwgen_uppercase", (value) => { this.config.uppercase = this.toBoolean(value) })
        this.readCookie("pwgen_lowercase", (value) => { this.config.lowercase = this.toBoolean(value) })
        this.readCookie("pwgen_digits", (value) => { this.config.digits = this.toBoolean(value) })
        this.readCookie("pwgen_symbols", (value) => { this.config.symbols = this.toBoolean(value) })
        this.readCookie("pwgen_avoidAmbiguous", (value) => { this.config.avoidAmbiguous = this.toBoolean(value) })
        this.readCookie("pwgen_pinLength", (value) => { this.config.pinLength = parseInt(value, 10) })
    }

    readCookie(name, assign) {
        const value = Cookies.get(name)
        if (typeof value === "string") {
            assign(value)
        }
    }

    configFromForm() {
        return {
            type: this.selectedType(),
            language: this.languageInputTarget.value,
            wordCount: Number(this.wordCountInputTarget.value),
            separator: this.separatorInputTarget.value,
            capitalize: this.capitalizeCheckboxTarget.checked,
            number: this.numberCheckboxTarget.checked,
            symbol: this.symbolCheckboxTarget.checked,
            passwordLength: Number(this.passwordLengthInputTarget.value),
            charset: this.charsetInputTarget.value,
            uppercase: this.uppercaseCheckboxTarget.checked,
            lowercase: this.lowercaseCheckboxTarget.checked,
            digits: this.digitsCheckboxTarget.checked,
            symbols: this.symbolsCheckboxTarget.checked,
            avoidAmbiguous: this.avoidAmbiguousCheckboxTarget.checked,
            pinLength: Number(this.pinLengthInputTarget.value)
        }
    }

    saveSettings() {
        this.config = this.configFromForm()
        Cookies.set("pwgen_type", this.config.type)
        Cookies.set("pwgen_language", this.config.language)
        Cookies.set("pwgen_wordCount", this.config.wordCount)
        Cookies.set("pwgen_separator", this.config.separator)
        Cookies.set("pwgen_capitalize", this.config.capitalize)
        Cookies.set("pwgen_number", this.config.number)
        Cookies.set("pwgen_symbol", this.config.symbol)
        Cookies.set("pwgen_passwordLength", this.config.passwordLength)
        Cookies.set("pwgen_charset", this.config.charset)
        Cookies.set("pwgen_uppercase", this.config.uppercase)
        Cookies.set("pwgen_lowercase", this.config.lowercase)
        Cookies.set("pwgen_digits", this.config.digits)
        Cookies.set("pwgen_symbols", this.config.symbols)
        Cookies.set("pwgen_avoidAmbiguous", this.config.avoidAmbiguous)
        Cookies.set("pwgen_pinLength", this.config.pinLength)
    }

    resetSettings() {
        this.config = Object.assign({}, this.configDefaults)
        this.loadForm()
    }

    configureGenerator() {
        if (this.gaEnabledValue === true) {
            gtag("event", "configure_pw_generator", {
                event_category: "engagement",
                event_label: "Configure Password Generator Dialog"
            })
        }
    }

    async testGenerate() {
        const config = this.configFromForm()
        this.syncEstimatedEntropy(config)

        const result = await this.requestGeneration(config)
        if (!result) {
            return
        }

        this.testPayloadAreaTarget.textContent = result.results[0]
        this.showEntropy(result.entropy_bits)
    }

    syncEstimatedEntropy(config = this.configFromForm()) {
        if (config.type !== "passphrase") {
            this.showEntropy(null)
            return
        }

        this.showEntropy(this.estimatedPassphraseEntropy(config))
    }

    estimatedPassphraseEntropy(config) {
        const sizes = this.wordlistSizesValue || {}
        const wordlistSize = Number(sizes[config.language] || sizes.en || 7776)
        let bits = config.wordCount * Math.log2(wordlistSize)
        if (config.number) {
            bits += Math.log2(100)
        }
        if (config.symbol) {
            bits += Math.log2(8)
        }
        return Math.round(bits * 10) / 10
    }

    showEntropy(bits) {
        if (!this.hasEntropyAreaTarget) {
            return
        }

        const value = Number(bits)
        const label = (bits == null || bits === "" || !Number.isFinite(value))
            ? ""
            : this.interpolate(this.langEntropyValue || "%{value} bits", { value })
        this.entropyAreaTargets.forEach((element) => {
            element.textContent = label
        })
    }

    producePassword() {
        const existingContent = this.payloadInputTarget.value.trim()

        if (existingContent.length > 0 && !this.isContentGenerated) {
            this.confirmationModal.show()
            return
        }

        this.generatePassword()
    }

    generateConfirm() {
        this.confirmationModal.hide()
        this.generatePassword()
    }

    async generatePassword() {
        const result = await this.requestGeneration(this.config)
        if (!result) {
            return
        }

        this.payloadInputTarget.value = result.results[0]
        this.payloadInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
        this.isContentGenerated = true

        if (this.gaEnabledValue) {
            gtag("event", "generate_password", {
                event_category: "engagement",
                event_label: "Generate a Password"
            })
        }
    }

    requestPayload(config) {
        const payload = { type: config.type, count: 1 }

        if (config.type === "passphrase") {
            Object.assign(payload, {
                language: config.language,
                word_count: config.wordCount,
                separator: config.separator,
                capitalize: config.capitalize,
                number: config.number,
                symbol: config.symbol
            })
        } else if (config.type === "password") {
            Object.assign(payload, {
                length: config.passwordLength,
                charset: config.charset,
                uppercase: config.uppercase,
                lowercase: config.lowercase,
                digits: config.digits,
                symbols: config.symbols,
                avoid_ambiguous: config.avoidAmbiguous
            })
        } else {
            payload.length = config.pinLength
        }

        return payload
    }

    async requestGeneration(config) {
        try {
            const response = await fetch(this.generateUrlValue, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Accept: "application/json"
                },
                body: JSON.stringify(this.requestPayload(config))
            })
            const body = await response.json()
            if (!response.ok) {
                window.alert(body.error || this.generationFailedMessage())
                return null
            }
            return body
        } catch (error) {
            window.alert(this.generationFailedMessage())
            return null
        }
    }

    generationFailedMessage() {
        return this.langFailedValue || "Password generation failed."
    }

    interpolate(template, replacements) {
        return Object.keys(replacements).reduce((result, key) => {
            return result.replace(`%{${key}}`, String(replacements[key]))
        }, template)
    }

    toBoolean(candidate) {
        if (typeof candidate === "string") {
            return candidate === "true"
        }
        if (typeof candidate === "boolean") {
            return candidate
        }
        return null
    }
}
