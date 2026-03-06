// Vendored TUS client: expose on window for multi_upload_controller.js.
// Loaded only on the file push form when TUS uploads are enabled.
import * as tus from "tus-js-client"
window.tus = tus
