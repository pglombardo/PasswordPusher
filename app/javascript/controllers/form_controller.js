import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "pushit",
    ]

    static values = {
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
        let submitButton = this.pushitTarget;
        let disableText = submitButton.getAttribute('data-disable-with')

        if (disableText === null) {
            disableText = 'Processing...'
        }

        if (submitButton.tagName == 'INPUT') {
            submitButton.value = disableText
        } else {
            submitButton.innerText = disableText
        }
        submitButton.disabled = true
    }
}
