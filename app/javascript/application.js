import "@hotwired/turbo-rails"
import "@rails/activestorage"
import "./controllers"
import "bootstrap"
import "./local_time_locales"

import LocalTime from "local-time"
import { setLocalTimeLocaleFromDocument } from "./local_time_locales"

// Check if Turbo Drive should be disabled
const turboDriveEnabled = document.querySelector('meta[name="turbo-drive-enabled"]')?.content === 'true'

if (!turboDriveEnabled) {
  console.log("⚡ Turbo Drive is disabled via environment variable")
  Turbo.session.drive = false
}

setLocalTimeLocaleFromDocument()
LocalTime.start()

document.addEventListener("turbo:load", () => LocalTime.run())
document.addEventListener("turbo:morph", () => {
  setLocalTimeLocaleFromDocument()
  LocalTime.run()
})
