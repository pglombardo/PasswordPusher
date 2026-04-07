import * as ActiveStorage from "@rails/activestorage"

import { Controller } from "@hotwired/stimulus"

import { formatBytes, formatDuration } from "../helpers/format_helpers"
import { setProgressBarComplete, setProgressBarError, setProgressBarProgress } from "../helpers/progress_bar_helpers"
import { cancelTusUploadOnServer, cloneTusUploadRow, parseTusUploadIdFromLocationHeader, setTusProgressDetails, signedIdFromTusSuccessPayload } from "../helpers/tus_upload_helpers"

/** One file input per row for direct (non-TUS) uploads; cloning + DataTransfer avoids sharing one DOM node across rows. */
function buildDirectUploadRowInput(templateInput, file) {
  const input = templateInput.cloneNode()
  input.removeAttribute('id')
  input.removeAttribute('multiple')
  input.removeAttribute('required')
  input.removeAttribute('data-action')
  input.classList.add('d-none')
  const dt = new DataTransfer()
  dt.items.add(file)
  input.files = dt.files
  return input
}

export default class extends Controller {
  // Target contains the selected file list; footerCount is the dynamic selection summary only.
  static targets = ["files", "footerCount"]

  static values = {
    maxFiles: Number,
    maxTusSize: Number,
    maxDirectSize: Number,
    fileTooLargeMessage: String,
    maxFilesMessage: String,
    finalizingLabel: String,
    footerSelectedTemplate: String,
    tusEnabled: Boolean,
    tusEndpoint: String,
    tusChunkSize: Number,
    filesInputName: String,
  }

  connect() {
    // Reset the file count
    this.fileCount = 0
    // Per-instance counter for TUS progress row ids (avoids collisions with multiple controllers)
    this.tusUploadId = 0
    // Number of uploads in progress (TUS or direct); used to disable submit button
    this.activeUploadCount = 0

    ActiveStorage.start()
    this.updateFilesFooter()

    // Only show Rails direct-upload UI when TUS is not used (avoids old animation when TUS is enabled)
    if (this.tusEnabledValue && typeof window.tus !== 'undefined') {
      return
    }

    this._boundDirectUploadInitialize = this._onDirectUploadInitialize.bind(this)
    this._boundDirectUploadStart = this._onDirectUploadStart.bind(this)
    this._boundDirectUploadProgress = this._onDirectUploadProgress.bind(this)
    this._boundDirectUploadError = this._onDirectUploadError.bind(this)
    this._boundDirectUploadEnd = this._onDirectUploadEnd.bind(this)

    window.addEventListener("direct-upload:initialize", this._boundDirectUploadInitialize)
    window.addEventListener("direct-upload:start", this._boundDirectUploadStart)
    window.addEventListener("direct-upload:progress", this._boundDirectUploadProgress)
    window.addEventListener("direct-upload:error", this._boundDirectUploadError)
    window.addEventListener("direct-upload:end", this._boundDirectUploadEnd)
  }

  disconnect() {
    if (this._boundDirectUploadInitialize) {
      window.removeEventListener("direct-upload:initialize", this._boundDirectUploadInitialize)
      window.removeEventListener("direct-upload:start", this._boundDirectUploadStart)
      window.removeEventListener("direct-upload:progress", this._boundDirectUploadProgress)
      window.removeEventListener("direct-upload:error", this._boundDirectUploadError)
      window.removeEventListener("direct-upload:end", this._boundDirectUploadEnd)
      this._boundDirectUploadInitialize = null
      this._boundDirectUploadStart = null
      this._boundDirectUploadProgress = null
      this._boundDirectUploadError = null
      this._boundDirectUploadEnd = null
    }
  }

  _dispatchUploadingState() {
    if (this.activeUploadCount > 0) {
      this.element.dispatchEvent(new CustomEvent("multi-upload:uploading", { bubbles: true }))
    } else {
      this.element.dispatchEvent(new CustomEvent("multi-upload:idle", { bubbles: true }))
    }
  }

  _onDirectUploadInitialize(event) {
    this.activeUploadCount += 1
    this._dispatchUploadingState()

    const { detail } = event
    const { id, file } = detail

    const preExistingBar = document.getElementById(`progress-${id}`)
    if (preExistingBar) preExistingBar.remove()

    const files = document.getElementById("selected-files")
    if (files) files.style.display = "none"

    const tpl = document.getElementById("direct-upload-row-template")
    const bars = document.getElementById("progress-bars")
    if (!tpl || !bars) return

    const li = tpl.content.cloneNode(true)
    const liEl = li.querySelector("li")
    const progressBar = li.querySelector(".direct-row-progress-bar")
    liEl.id = `progress-${id}`
    progressBar.id = `direct-upload-${id}`
    progressBar.setAttribute("aria-label", file.name)
    progressBar.append(file.name)
    bars.append(li)
  }

  _onDirectUploadStart(event) {
    setProgressBarProgress(document.getElementById(`direct-upload-${event.detail.id}`), 0)
  }

  _onDirectUploadProgress(event) {
    const { id, progress } = event.detail
    setProgressBarProgress(document.getElementById(`direct-upload-${id}`), progress)
  }

  _onDirectUploadError(event) {
    event.preventDefault()
    const { id, error } = event.detail
    setProgressBarError(document.getElementById(`direct-upload-${id}`), error)
  }

  _onDirectUploadEnd(event) {
    setProgressBarComplete(document.getElementById(`direct-upload-${event.detail.id}`))
    this.activeUploadCount = Math.max(0, this.activeUploadCount - 1)
    this._dispatchUploadingState()
  }

  async addFile(event) {
    event.preventDefault()
    event.stopPropagation()

    const originalInput = event.target
    const maxFiles = this.maxFilesValue

    const fileList = originalInput.files
    if (!fileList || fileList.length === 0) return

    const arrayLength = fileList.length
    if (arrayLength > maxFiles || this.fileCount + arrayLength > maxFiles) {
      const maxFilesMsg = this.hasMaxFilesMessageValue
      ? this.maxFilesMessageValue.replace('%{count}', String(maxFiles))
      : `You can only upload ${maxFiles} files at a time.`
      alert(maxFilesMsg)
      originalInput.value = ''
      return
    }

    const maxSize = this.tusEnabledValue
      ? (this.hasMaxTusSizeValue ? this.maxTusSizeValue : 0)
      : (this.hasMaxDirectSizeValue ? this.maxDirectSizeValue : 0)
    for (let i = 0; i < arrayLength; i++) {
      const file = originalInput.files[i]
      if (maxSize > 0 && file.size > maxSize) {
        const msg = this.hasFileTooLargeMessageValue
          ? this.fileTooLargeMessageValue.replace('%{filename}', file.name).replace('%{size}', formatBytes(maxSize))
          : `"${file.name}" is too large. Max size per file is ${formatBytes(maxSize)}.`
        alert(msg)
        originalInput.value = ''
        return
      }
    }

    if (this.tusEnabledValue && typeof window.tus !== 'undefined') {
      await this.addFileViaTus(originalInput, arrayLength)
      return
    }

    for (let i = 0; i < arrayLength; i++) {
      this.fileCount += 1
      const file = originalInput.files[i]
      const fileName = file.name + ' (' + formatBytes(file.size) + ')'

      const rowInput = buildDirectUploadRowInput(originalInput, file)

      const li = document.createElement("li")
      li.classList.add("list-group-item", "selected-file", "list-group-item-primary", "small")
      li.appendChild(rowInput)
      const trashLink = document.createElement("a")
      trashLink.setAttribute("data-action", "multi-upload#removeFile")
      trashLink.setAttribute("href", "#")
      trashLink.innerHTML = "<em class=\"bi bi-trash me-2\"></em>"
      li.appendChild(trashLink)
      li.appendChild(document.createTextNode(fileName))
      this.filesTarget.append(li)
      rowInput.dispatchEvent(new Event("change", { bubbles: true }))
    }

    originalInput.removeAttribute('required')
    originalInput.value = ''
    this.updateFilesFooter()
  }

  // One TUS upload at a time per batch so session[:tus_active_upload_ids] updates never race
  // (concurrent POST/PATCH last-write-wins can strand an id and block push create).
  async addFileViaTus(originalInput, arrayLength) {
    const controller = this
    const endpoint = this.tusEndpointValue || '/uploads'
    const inputName = this.filesInputNameValue || 'push[files][]'
    const files = originalInput.files
    const tusTpl = document.getElementById("tus-upload-row-template")
    const selectedTpl = document.getElementById("selected-file-row-template")
    const bars = document.getElementById("progress-bars")

    if (!bars) return

    this.fileCount += arrayLength
    this.updateFilesFooter()

    for (let i = 0; i < arrayLength; i++) {
      const file = files[i]
      const id = ++this.tusUploadId
      const fileName = file.name + ' (' + formatBytes(file.size) + ')'

      const { li, progressBar, pauseBtn, resumeBtn, rowNode } = cloneTusUploadRow(tusTpl, id, file)

      setTusProgressDetails(progressBar, 0, file.size)
      bars.append(rowNode)

      const uploadStartTime = Date.now()

      await new Promise((resolve) => {
        controller.activeUploadCount += 1
        controller._dispatchUploadingState()

        const chunkSize = this.hasTusChunkSizeValue && this.tusChunkSizeValue > 0
          ? this.tusChunkSizeValue
          : 2 * 1024 * 1024 // 2 MB fallback
        const opts = {
          endpoint: endpoint,
          uploadLength: file.size,
          chunkSize,
          metadata: {
            filename: file.name,
            filetype: file.type || 'application/octet-stream'
          },
          retryDelays: [1000, 3000],
          onAfterResponse: (req, res) => {
            if (req.getMethod() === 'POST' && res.getStatus() === 201) {
              const sid = parseTusUploadIdFromLocationHeader(res.getHeader('Location'))
              if (sid) li.dataset.tusServerUploadId = sid
            }
          },
          onProgress: (bytesUploaded, bytesTotal) => {
            const finalizingLabel = this.hasFinalizingLabelValue ? this.finalizingLabelValue : null
            setTusProgressDetails(progressBar, bytesUploaded, bytesTotal, finalizingLabel)
          },
          onChunkComplete: (bytesAccepted, bytesTotal) => {
            if (bytesAccepted < bytesTotal) {
              if (pauseBtn && pauseBtn.classList.contains('d-none') && resumeBtn && resumeBtn.classList.contains('d-none')) {
                pauseBtn.classList.remove('d-none')
              }
            }
          },
          onSuccess: (payload) => {
            controller.activeUploadCount = Math.max(0, controller.activeUploadCount - 1)
            controller._dispatchUploadingState()
            const signedId = signedIdFromTusSuccessPayload(payload)
            if (!signedId) {
              setProgressBarError(progressBar, "Missing signed ID")
              controller.fileCount -= 1
              controller.updateFilesFooter()
              resolve()
              return
            }
            const tusServerUploadId = li.dataset.tusServerUploadId
            li.remove()
            const elapsedMs = Date.now() - uploadStartTime
            const durationStr = formatDuration(elapsedMs)
            const uploadTimeLabel = durationStr ? `Uploaded in ${durationStr}` : ''
            if (selectedTpl) {
              const row = selectedTpl.content.cloneNode(true)
              const selectedLi = row.querySelector("li")
              if (tusServerUploadId) selectedLi.dataset.tusServerUploadId = tusServerUploadId
              const input = row.querySelector(".selected-file-input")
              input.name = inputName
              input.value = signedId
              row.querySelector(".selected-file-name").textContent = fileName
              const timeEl = row.querySelector(".selected-file-upload-time")
              if (timeEl) timeEl.textContent = uploadTimeLabel
              controller.filesTarget.append(row)
            } else {
              const selectedFile = document.createElement("li")
              selectedFile.classList.add("list-group-item", "selected-file", "list-group-item-primary", "small")
              if (tusServerUploadId) selectedFile.dataset.tusServerUploadId = tusServerUploadId
              const hiddenInput = document.createElement("input")
              hiddenInput.type = "hidden"
              hiddenInput.name = inputName
              hiddenInput.value = signedId
              selectedFile.appendChild(hiddenInput)
              const trashLink = document.createElement("a")
              trashLink.setAttribute("data-action", "multi-upload#removeFile")
              trashLink.setAttribute("href", "#")
              trashLink.innerHTML = "<em class=\"bi bi-trash me-2\"></em>"
              selectedFile.appendChild(trashLink)
              selectedFile.appendChild(document.createTextNode(fileName + (uploadTimeLabel ? ` · ${uploadTimeLabel}` : '')))
              controller.filesTarget.append(selectedFile)
            }
            controller.updateFilesFooter()
            resolve()
          },
          onError: (err) => {
            cancelTusUploadOnServer(upload.url)
            controller.activeUploadCount = Math.max(0, controller.activeUploadCount - 1)
            controller._dispatchUploadingState()
            setProgressBarError(progressBar, err.message)
            controller.fileCount -= 1
            controller.updateFilesFooter()
            resolve()
          }
        }

        let upload = new window.tus.Upload(file, opts)

        pauseBtn.addEventListener('click', () => {
          upload.abort()
          pauseBtn.classList.add('d-none')
          resumeBtn.classList.remove('d-none')
          progressBar.classList.remove('progress-bar-animated')
        })

        resumeBtn.addEventListener('click', () => {
          const uploadUrl = upload.url
          if (!uploadUrl) return
          resumeBtn.classList.add('d-none')
          pauseBtn.classList.remove('d-none')
          progressBar.classList.add('progress-bar-animated')
          const startResume = (offset) => {
            setTusProgressDetails(progressBar, offset, file.size)
            opts.uploadUrl = uploadUrl
            upload = new window.tus.Upload(file, opts)
            upload.start()
          }
          const offsetFromUpload = (upload.offset != null && typeof upload.offset === 'number') ? upload.offset : null
          if (offsetFromUpload != null) {
            startResume(offsetFromUpload)
          } else {
            fetch(uploadUrl, { method: 'HEAD', credentials: 'same-origin' })
              .then((res) => {
                const h = res.headers.get('Upload-Offset') || res.headers.get('upload-offset')
                return h ? parseInt(h, 10) : 0
              })
              .then((offset) => startResume(Number.isFinite(offset) ? offset : 0))
              .catch(() => startResume(0))
          }
        })

        upload.start()
      })
    }

    originalInput.removeAttribute('required')
    this.updateFilesFooter()
    // Clear input after a tick to avoid re-triggering 'change' in same event loop
    setTimeout(() => { originalInput.value = "" }, 0)
  }

  updateFilesFooter() {
    if (!this.hasFooterCountTarget) return
    const n = this.fileCount
    if (n <= 0) {
      this.footerCountTarget.textContent = ''
      return
    }
    const template = this.footerSelectedTemplateValue?.trim()
      ? this.footerSelectedTemplateValue
      : '%{count} file(s) selected.'
    this.footerCountTarget.textContent = template.replace(/%\{count\}/g, String(n))
  }

  removeFile(event) {
    event.preventDefault()
    const listItem = event.target.closest('li')
    if (!listItem || !listItem.parentNode) return

    const tusId = listItem.dataset.tusServerUploadId
    if (tusId) {
      const base = (this.tusEndpointValue || '/uploads').replace(/\/$/, '')
      cancelTusUploadOnServer(`${base}/${encodeURIComponent(tusId)}`)
    }

    listItem.remove()
    this.fileCount -= 1
    this.updateFilesFooter()
  }
}
