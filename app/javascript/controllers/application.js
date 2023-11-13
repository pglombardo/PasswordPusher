import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

console.log('Welcome to Password Pusher! ( ◑‿◑)ɔ┏🍟--🍔┑٩(^◡^ )')
console.log(' --> 🏝 May all your pushes be stored securely, read once and expired quickly.')

const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)");

if (prefersDarkScheme.matches) {
    document.body.classList.add('dark-mode')
} else {
    document.body.classList.remove('dark-mode')
}

export { application }
