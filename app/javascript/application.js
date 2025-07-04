import "@hotwired/turbo-rails"
import "@rails/activestorage"

// Selective Bootstrap imports - only load what's needed
import 'bootstrap/js/dist/modal'
import 'bootstrap/js/dist/dropdown'
import 'bootstrap/js/dist/collapse'
import 'bootstrap/js/dist/alert'
import 'bootstrap/js/dist/button'
import 'bootstrap/js/dist/tooltip'
import 'bootstrap/js/dist/popover'

import "./controllers"

// Service Worker for performance optimization
import "./sw_registration"

// Check if Turbo Drive should be disabled
const turboDriveEnabled = document.querySelector('meta[name="turbo-drive-enabled"]')?.content === 'true'

if (!turboDriveEnabled) {
  console.log("⚡ Turbo Drive is disabled via environment variable")
  Turbo.session.drive = false
}
