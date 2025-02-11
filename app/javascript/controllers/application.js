import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

console.log('Welcome to Password Pusher! ( ◑‿◑)ɔ┏🍟--🍔┑٩(^◡^ )')
console.log(' --> 🏝 May all your pushes be stored securely, read once and expired quickly.')

export { application }
