import { Controller } from "@hotwired/stimulus"
import Cookies from 'js-cookie'
import generatePassword from "omgopass";

export default class extends Controller {
    static targets = [
        "testPayloadArea",
        "payloadInput",
        "generatePasswordButton",

        "numSyllablesInput",
        "minSyllableLengthInput",
        "maxSyllableLengthInput",
        "includeNumbersCheckbox",
        "useTitleCaseCheckbox",
        "useSeparatorsCheckbox",
        "separatorsInput",
        "vowelsInput",
        "consonantsInput",
    ]

    static values = {
        gaEnabled: Boolean,

        useNumbersDefault: Boolean,
        titleCasedDefault: Boolean,
        useSeparatorsDefault: Boolean,
        consonantsDefault: String,
        vowelsDefault: String,
        separatorsDefault: String,
        minSyllableLengthDefault: Number,
        maxSyllableLengthDefault: Number,
        syllablesCountDefault: Number,

    }

    initialize() {
        this.config_defaults = {}
        this.config = {}

    }

    connect() {
        this.loadSettings()
        this.loadForm()
    }

    loadForm() {
        this.numSyllablesInputTarget.value = this.config.syllablesCount
        this.minSyllableLengthInputTarget.value = this.config.minSyllableLength
        this.maxSyllableLengthInputTarget.value = this.config.maxSyllableLength
        this.includeNumbersCheckboxTarget.checked = this.config.hasNumbers
        this.useTitleCaseCheckboxTarget.checked = this.config.titlecased
        this.useSeparatorsCheckboxTarget.checked = this.config.use_separators
        this.separatorsInputTarget.value = this.config.separators
        this.vowelsInputTarget.value = this.config.vowels
        this.consonantsInputTarget.value = this.config.consonants
    }

    loadSettings() {
        this.config_defaults = {
            hasNumbers:        this.useNumbersDefaultValue,
            titlecased:        this.titleCasedDefaultValue,
            use_separators:    this.useSeparatorsDefaultValue,
            consonants:        this.consonantsDefaultValue,
            vowels:            this.vowelsDefaultValue,
            separators:        this.separatorsDefaultValue,
            maxSyllableLength: this.maxSyllableLengthDefaultValue,
            minSyllableLength: this.minSyllableLengthDefaultValue,
            syllablesCount:    this.syllablesCountDefaultValue,
        };

        this.config = Object.assign({}, this.config_defaults);

        if (typeof Cookies.get('pwgen_hasNumbers') == 'string') {
            this.config.hasNumbers = this.toBoolean(Cookies.get('pwgen_hasNumbers'))
        }
        if (typeof Cookies.get('pwgen_titlecased') == 'string') {
            this.config.titlecased = this.toBoolean(Cookies.get('pwgen_titlecased'))
        }
        if (typeof Cookies.get('pwgen_use_separators') == 'string') {
            this.config.use_separators = this.toBoolean(Cookies.get('pwgen_use_separators'))
        }
        if (typeof Cookies.get('pwgen_consonants') == 'string') {
            this.config.consonants = Cookies.get('pwgen_consonants')
        }
        if (typeof Cookies.get('pwgen_vowels') == 'string') {
            this.config.vowels = Cookies.get('pwgen_vowels')
        }
        if (typeof Cookies.get('pwgen_separators') == 'string') {
            this.config.separators = Cookies.get('pwgen_separators')
        }
        if (typeof Cookies.get('pwgen_maxSyllableLength') == 'string') {
            this.config.maxSyllableLength = parseInt(Cookies.get('pwgen_maxSyllableLength'))
        }
        if (typeof Cookies.get('pwgen_minSyllableLength') == 'string') {
            this.config.minSyllableLength = parseInt(Cookies.get('pwgen_minSyllableLength'))
        }
        if (typeof Cookies.get('pwgen_syllablesCount') == 'string') {
            this.config.syllablesCount = parseInt(Cookies.get('pwgen_syllablesCount'))
        }
    }

    saveSettings(event) {
        Cookies.set('pwgen_hasNumbers', this.includeNumbersCheckboxTarget.checked)
        Cookies.set('pwgen_titlecased', this.useTitleCaseCheckboxTarget.checked)
        Cookies.set('pwgen_use_separators', this.useSeparatorsCheckboxTarget.checked)
        Cookies.set('pwgen_consonants', this.consonantsInputTarget.value)
        Cookies.set('pwgen_vowels', this.vowelsInputTarget.value)
        Cookies.set('pwgen_separators', this.separatorsInputTarget.value)
        Cookies.set('pwgen_maxSyllableLength', this.maxSyllableLengthInputTarget.value)
        Cookies.set('pwgen_minSyllableLength', this.minSyllableLengthInputTarget.value)
        Cookies.set('pwgen_syllablesCount', this.numSyllablesInputTarget.value)

        this.config = {
            hasNumbers: this.includeNumbersCheckboxTarget.checked,
            titlecased: this.useTitleCaseCheckboxTarget.checked,
            use_separators: this.useSeparatorsCheckboxTarget.checked,
            consonants: this.consonantsInputTarget.value,
            vowels: this.vowelsInputTarget.value,
            separators: this.separatorsInputTarget.value,
            maxSyllableLength: Number(this.maxSyllableLengthInputTarget.value),
            minSyllableLength: Number(this.minSyllableLengthInputTarget.value),
            syllablesCount: Number(this.numSyllablesInputTarget.value)
        }
    }

    resetSettings(event) {
        this.config = Object.assign({}, this.config_defaults);
        this.loadForm()
    }

    configureGenerator(event) {
        if (this.gaEnabledValue == true) {
            gtag('event', 'configure_pw_generator',
                    { 'event_category' : 'engagement',
                    'event_label' : 'Configure Password Generator Dialog' });
        }
    }

    testGenerate(event) {
        let testConfig = {
            hasNumbers: this.includeNumbersCheckboxTarget.checked,
            titlecased: this.useTitleCaseCheckboxTarget.checked,
            use_separators: this.useSeparatorsCheckboxTarget.checked,
            consonants: this.consonantsInputTarget.value,
            vowels: this.vowelsInputTarget.value,
            separators: this.separatorsInputTarget.value,
            maxSyllableLength: Number(this.maxSyllableLengthInputTarget.value),
            minSyllableLength: Number(this.minSyllableLengthInputTarget.value),
            syllablesCount: Number(this.numSyllablesInputTarget.value)
        }
        if (testConfig.use_separators === false) {
            testConfig.separators = ''
        }
        this.testPayloadAreaTarget.innerText = generatePassword(testConfig)
    }

    producePassword(event) {
        if (this.config.use_separators === false) {
            this.config.separators = ''
        }
        this.payloadInputTarget.value = generatePassword(this.config)

        if (this.gaEnabledValue) {
            gtag('event', 'generate_password',
                    { 'event_category' : 'engagement',
                    'event_label' : 'Generate a Password' });
        }
    }

    toBoolean(candidate) {
        if (candidate) {
            if (typeof candidate === 'string') {
                return candidate == 'true';
            } else if (typeof candidate === 'boolean') {
                return candidate;
            }
        }
        return null;
    }
}
