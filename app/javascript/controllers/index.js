import { application } from "./application"

// Eager load essential controllers that are needed on most pages
import GdprController from "./gdpr_controller"
import ThemeController from "./theme_controller"
import CopyController from "./copy_controller"
import FormController from "./form_controller"

// Register essential controllers immediately
application.register("gdpr", GdprController)
application.register("theme", ThemeController)
application.register("copy", CopyController)
application.register("form", FormController)

// Lazy load heavy controllers only when needed
const lazyControllerRegistry = new Map()

function registerLazyController(name, importFn) {
  lazyControllerRegistry.set(name, importFn)
  
  // Create a placeholder controller that loads the real one on first use
  application.register(name, class extends application.Controller {
    async connect() {
      if (lazyControllerRegistry.has(name)) {
        const importFn = lazyControllerRegistry.get(name)
        const { default: Controller } = await importFn()
        lazyControllerRegistry.delete(name)
        application.register(name, Controller)
        
        // Reconnect with the real controller
        this.disconnect()
        const newController = new Controller(this.context)
        newController.connect()
      }
    }
  })
}

// Register heavy controllers for lazy loading
registerLazyController('knobs', () => import('./knobs_controller'))
registerLazyController('multi-upload', () => import('./multi_upload_controller'))
registerLazyController('pwgen', () => import('./pwgen_controller'))
registerLazyController('passwords', () => import('./passwords_controller'))
