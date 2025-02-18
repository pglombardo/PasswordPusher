//= require popper
import "@hotwired/turbo-rails"
import "@rails/activestorage"
import "bootstrap"
import "./controllers"

// Check if Turbo Drive should be disabled
const turboDriveEnabled = document.querySelector('meta[name="turbo-drive-enabled"]')?.content === 'true'

if (!turboDriveEnabled) {
  console.log("⚡ Turbo Drive is disabled via environment variable")
  Turbo.session.drive = false
}
