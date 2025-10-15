// Import all controllers
import "./controllers/application"
import "./controllers/copy_controller"
import "./controllers/form_controller"
import "./controllers/gdpr_controller"
import "./controllers/knobs_controller"
import "./controllers/multi_upload_controller"
import "./controllers/passwords_controller"
import "./controllers/pwgen_controller"
import "./controllers/theme_controller"

import { Application } from "@hotwired/stimulus"

window.Stimulus = Application.start()

