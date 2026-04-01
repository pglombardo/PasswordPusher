import CopyController from "./copy_controller"
import CountdownController from "./countdown_controller"
import FormController from "./form_controller"
import GdprController from "./gdpr_controller"
import KnobsController from "./knobs_controller"
import MultiUploadController from "./multi_upload_controller"
import PWGenController from "./pwgen_controller"
import PasswordsController from "./passwords_controller"
import ThemeController from "./theme_controller"
import { application } from "./application"

application.register("gdpr", GdprController)
application.register("copy", CopyController)
application.register("countdown", CountdownController)
application.register("pwgen", PWGenController)
application.register("form", FormController)
application.register("knobs", KnobsController)
application.register("passwords", PasswordsController)
application.register("multi-upload", MultiUploadController)
application.register("theme", ThemeController)
