import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
    ]

    static values = {
    }

    initialize() {
        const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)");

        if (prefersDarkScheme.matches) {
            document.body.classList.add('dark-mode')
        }
    }
}