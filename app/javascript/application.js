//= require popper
import "@hotwired/turbo-rails"
import "@rails/activestorage"
import "bootstrap"
import "./controllers"

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
