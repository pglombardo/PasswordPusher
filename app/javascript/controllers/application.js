import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

console.log('Welcome to Password Pusher! ( ◑‿◑)ɔ┏🍟--🍔┑٩(^◡^ )')
console.log(' --> 🏝 May all your pushes be stored securely, read once and expired quickly.')

const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)");

// Function to handle theme changes
const handleThemeChange = (e) => {
    if (e.matches) {
        document.documentElement.setAttribute('data-bs-theme', 'dark')
    } else {
        document.documentElement.setAttribute('data-bs-theme', 'light')
    }
}

// Initial check
handleThemeChange(prefersDarkScheme);

// Listen for changes
prefersDarkScheme.addEventListener('change', handleThemeChange);

export { application }
