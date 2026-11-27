import { Controller } from "@hotwired/stimulus"
import Cookies from 'js-cookie'

export default class extends Controller {
    static targets = [
        "daysRange", "daysRangeLabel",
        "viewsRange", "viewsRangeLabel",
        "saveSettings",
        "deletableByViewerCheckbox",
        "retrievalStepCheckbox",
        "generatePasswordButton"
     ]
    static values = {
        tabName: String,

        dayLabels: Object,
        defaultDays: Number,

        viewLabels: Object,
        defaultViews: Number,

        langSave: String,
        langSaved: String,

        defaultRetrievalStep: Boolean,
        defaultDeletableByViewer: Boolean,
    }

    connect() {
        this.loadSettings()
    }

    updateDaysSlider(event) {
        this.daysRangeLabelTarget.innerText = this.labelFor(this.dayLabelsValue, event.target.value)
    }

    updateViewsSlider(event) {
        this.viewsRangeLabelTarget.innerText = this.labelFor(this.viewLabelsValue, event.target.value)
    }

    loadSettings() {
        this.daysRangeTarget.value = Cookies.get(`pwpush_${this.tabNameValue}_days`) || this.defaultDaysValue
        this.daysRangeLabelTarget.innerText = this.labelFor(this.dayLabelsValue, this.daysRangeTarget.value)
        this.viewsRangeTarget.value = Cookies.get(`pwpush_${this.tabNameValue}_views`) || this.defaultViewsValue
        this.viewsRangeLabelTarget.innerText = this.labelFor(this.viewLabelsValue, this.viewsRangeTarget.value)

        // Only load checkbox values from cookies if creating a new push (not editing)
        // Check if the checkbox has x-default attribute - if yes, we're creating, not editing
        if (this.hasRetrievalStepCheckboxTarget) {
            let hasDefaultAttr = this.retrievalStepCheckboxTarget.hasAttribute('x-default')
            if (hasDefaultAttr) {
                let checkboxValue = Cookies.get(`pwpush_${this.tabNameValue}_retrieval_step`)
                if (typeof checkboxValue == 'string') {
                    this.retrievalStepCheckboxTarget.checked = this.toBoolean(checkboxValue)
                } else {
                    this.retrievalStepCheckboxTarget.checked = this.defaultRetrievalStepValue
                }
            }
            // else: when editing, keep the value from server (already set in checked attribute)
        }
        if (this.hasDeletableByViewerCheckboxTarget) {
            let hasDefaultAttr = this.deletableByViewerCheckboxTarget.hasAttribute('x-default')
            if (hasDefaultAttr) {
                let checkboxValue = Cookies.get(`pwpush_${this.tabNameValue}_deletable_by_viewer`)
                if (typeof checkboxValue == 'string') {
                    this.deletableByViewerCheckboxTarget.checked = this.toBoolean(checkboxValue)
                } else {
                    this.deletableByViewerCheckboxTarget.checked = this.defaultDeletableByViewerValue
                }
            }
            // else: when editing, keep the value from server (already set in checked attribute)
        }
    }

    saveSettings(event) {
        event.preventDefault()
        Cookies.set(`pwpush_${this.tabNameValue}_days`, this.daysRangeTarget.value, { expires: 365 })
        Cookies.set(`pwpush_${this.tabNameValue}_views`, this.viewsRangeTarget.value, { expires: 365 })

        if (this.hasDeletableByViewerCheckboxTarget) {
            Cookies.set(`pwpush_${this.tabNameValue}_deletable_by_viewer`, this.deletableByViewerCheckboxTarget.checked, { expires: 365 })
        }
        if (this.hasRetrievalStepCheckboxTarget) {
            Cookies.set(`pwpush_${this.tabNameValue}_retrieval_step`, this.retrievalStepCheckboxTarget.checked, { expires: 365 })
        }

        let defaultTextValue = this.langSaveValue
        event.target.innerHTML = this.langSavedValue

        setTimeout(function() {
            event.target.innerText = defaultTextValue
        }, 1000);
        return false
    }

    labelFor(labels, value) {
        const key = String(value)
        const label = labels[key]
        if (label == null || label === "") {
            return key
        }
        return label
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
