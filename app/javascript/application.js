import "@hotwired/turbo-rails"
import "@rails/activestorage"
import "./controllers"
import "bootstrap"

import LocalTime from "local-time"

// Check if Turbo Drive should be disabled
const turboDriveEnabled = document.querySelector('meta[name="turbo-drive-enabled"]')?.content === 'true'

if (!turboDriveEnabled) {
  console.log("⚡ Turbo Drive is disabled via environment variable")
  Turbo.session.drive = false
}

LocalTime.start()

document.addEventListener("turbo:load", () => LocalTime.run())
document.addEventListener("turbo:morph", () => LocalTime.run())
