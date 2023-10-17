import { Controller } from "@hotwired/stimulus"
import { spoilerAlert } from "../../../vendor/javascript/spoiler-alert"

export default class extends Controller {
    static targets = [
        "payloadInput",
        "currentChars",
        "maximumChars",
    ]

    static values = {
    }

    connect() {
        spoilerAlert('spoiler, .spoiler', {max: 10, partial: 4});
    }

    updateCharacterCount(event) {
        let characterCount = this.payloadInputTarget.value.length;
        this.currentCharsTarget.textContent = characterCount;

        if (characterCount >= 1048576) {
            this.maximumCharsTarget.style.color = '#F91A00'
            this.currentCharsTarget.style.color = '#F91A00'
        }
    }
}
