import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
    ]

    static values = {
    }

    disableWith(event) {
        debugger
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

        let form = event.target.form
        if (typeof form !== 'undefined') {
            form.submit()
        }
    }

}