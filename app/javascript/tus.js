// Expose tus-js-client on window for multi_upload_controller.js (file push form when TUS is enabled).
import * as tus from "tus-js-client"
window.tus = tus
