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
        langDay: String,
        langDays: String,
        defaultDays: Number,

        langView: String,
        langViews: String,
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
        let days = event.target.value
        if (days > 1) {
            this.daysRangeLabelTarget.innerText = days + " " + this.langDaysValue;
        } else {
            this.daysRangeLabelTarget.innerText = days + " " + this.langDayValue;
        }
    }

    updateViewsSlider(event) {
        let views = event.target.value
        if (views > 1) {
            this.viewsRangeLabelTarget.innerText = views + " " + this.langViewsValue;
        } else {
            this.viewsRangeLabelTarget.innerText = views + " " + this.langViewValue;
        }
    }

    loadSettings() {
        this.daysRangeTarget.value = Cookies.get('pwpush_days') || this.defaultDaysValue
        this.daysRangeLabelTarget.innerText = this.daysRangeTarget.value + " " + this.langDaysValue
        this.viewsRangeTarget.value = Cookies.get('pwpush_views') || this.defaultViewsValue
        this.viewsRangeLabelTarget.innerText = this.viewsRangeTarget.value + " " + this.langViewsValue

        if (this.hasRetrievalStepCheckboxTarget) {
            let checkboxValue = Cookies.get('pwpush_retrieval_step')
            if (typeof checkboxValue == 'string') {
                this.retrievalStepCheckboxTarget.checked = this.toBoolean(checkboxValue)
            } else {
                this.retrievalStepCheckboxTarget.checked = this.defaultRetrievalStepValue
            }
        }
        if (this.hasDeletableByViewerCheckboxTarget) {
            let checkboxValue = Cookies.get('pwpush_deletable_by_viewer')
            if (typeof checkboxValue == 'string') {
                this.deletableByViewerCheckboxTarget.checked = this.toBoolean(checkboxValue)
            } else {
                this.deletableByViewerCheckboxTarget.checked = this.defaultDeletableByViewerValue
            }
        }
    }

    saveSettings(event) {
        event.preventDefault()
        Cookies.set('pwpush_days', this.daysRangeTarget.value, { expires: 365 })
        Cookies.set('pwpush_views', this.viewsRangeTarget.value, { expires: 365 })

        if (this.hasDeletableByViewerCheckboxTarget) {
            Cookies.set('pwpush_deletable_by_viewer', this.deletableByViewerCheckboxTarget.checked, { expires: 365 })
        }
        if (this.hasRetrievalStepCheckboxTarget) {
            Cookies.set('pwpush_retrieval_step', this.retrievalStepCheckboxTarget.checked, { expires: 365 })
        }

        let defaultTextValue = this.langSaveValue
        event.target.innerHTML = this.langSavedValue

        setTimeout(function() {
            event.target.innerText = defaultTextValue
        }, 1000);
        return false
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
