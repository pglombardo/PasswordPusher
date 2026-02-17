import * as ActiveStorage from "@rails/activestorage"

import { Controller } from "@hotwired/stimulus"

let fileCount = 0

function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const dm = decimals < 0 ? 0 : decimals
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i]
}

function formatDuration(ms) {
  if (!Number.isFinite(ms) || ms < 0) return ''
  const sec = Math.floor(ms / 1000)
  if (sec < 60) return `${sec}s`
  const min = Math.floor(sec / 60)
  const s = sec % 60
  if (min < 60) return s > 0 ? `${min}m ${s}s` : `${min}m`
  const h = Math.floor(min / 60)
  const m = min % 60
  return [h + 'h', m > 0 ? m + 'm' : '', s > 0 ? s + 's' : ''].filter(Boolean).join(' ')
}

// Shared progress bar API for both direct and TUS uploads
function setProgressBarProgress(el, percent) {
  if (!el) return
  el.setAttribute('aria-valuenow', String(percent))
  el.style.width = percent + '%'
}

function setTusProgressDetails(progressBar, bytesUploaded, bytesTotal, finalizingLabel) {
  if (!progressBar) return
  const pct = bytesTotal > 0 ? Math.round((bytesUploaded / bytesTotal) * 100) : 0
  setProgressBarProgress(progressBar, pct)
  const row = progressBar.closest('li')
  const sizeEl = row?.querySelector('.tus-row-size')
  if (!sizeEl) return
  if (bytesTotal > 0 && bytesUploaded >= bytesTotal) {
    setTusFinalizing(row, sizeEl, finalizingLabel)
  } else {
    sizeEl.textContent = `${formatBytes(bytesUploaded)} of ${formatBytes(bytesTotal)}`
  }
}

function setTusFinalizing(row, sizeEl, finalizingLabel) {
  if (row?.dataset.tusFinalizing === 'true') return
  row.dataset.tusFinalizing = 'true'
  const label = finalizingLabel || 'Finalizing…'
  sizeEl.textContent = ''
  sizeEl.classList.add('d-flex', 'align-items-center', 'gap-1')
  sizeEl.appendChild(document.createTextNode(label))
  const spinner = document.createElement('span')
  spinner.className = 'spinner-border spinner-border-sm'
  spinner.setAttribute('role', 'status')
  spinner.setAttribute('aria-hidden', 'true')
  sizeEl.appendChild(spinner)
  const bar = row.querySelector('.tus-row-progress-bar, [role="progressbar"]')
  if (bar) bar.setAttribute('aria-label', label)
}

function setProgressBarError(el, message) {
  if (!el) return
  el.classList.add('bg-danger')
  const msg = message || 'Upload failed'
  el.setAttribute('aria-label', msg)
  // Show error text visibly (aria-label is for screen readers only)
  const row = el.closest('li')
  if (row) {
    let errEl = row.querySelector('.upload-error-text')
    if (!errEl) {
      errEl = document.createElement('span')
      errEl.className = 'upload-error-text text-danger small d-block mt-1'
      row.appendChild(errEl)
    }
    errEl.textContent = msg
    errEl.setAttribute('role', 'alert')
  }
}

function setProgressBarComplete(el) {
  if (!el) return
  el.setAttribute('aria-label', 'Complete')
}

export default class extends Controller {
  // Target contains the selected file list
  static targets = ["files"]

  static values = {
    maxFiles: Number,
    maxTusSize: Number,
    fileTooLargeMessage: String,
    maxFilesMessage: String,
    finalizingLabel: String,
    tusEnabled: Boolean,
    tusEndpoint: String,
    filesInputName: String,
  }

  connect() {
    // Reset the file count
    fileCount = 0
    // Per-instance counter for TUS progress row ids (avoids collisions with multiple controllers)
    this.tusUploadId = 0

    ActiveStorage.start()

    // Only show Rails direct-upload UI when TUS is not used (avoids old animation when TUS is enabled)
    if (this.tusEnabledValue && typeof window.tus !== 'undefined') {
      return
    }

    addEventListener("direct-upload:initialize", event => {
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
    })

    addEventListener("direct-upload:start", event => {
      setProgressBarProgress(document.getElementById(`direct-upload-${event.detail.id}`), 0)
    })

    addEventListener("direct-upload:progress", event => {
      const { id, progress } = event.detail
      setProgressBarProgress(document.getElementById(`direct-upload-${id}`), progress)
    })

    addEventListener("direct-upload:error", event => {
      event.preventDefault()
      const { id, error } = event.detail
      setProgressBarError(document.getElementById(`direct-upload-${id}`), error)
    })

    addEventListener("direct-upload:end", event => {
      setProgressBarComplete(document.getElementById(`direct-upload-${event.detail.id}`))
    })
  }

  addFile(event) {
    event.preventDefault()
    event.stopPropagation()

    const originalInput = event.target
    const originalParent = originalInput.parentNode
    const maxFiles = this.maxFilesValue

    const fileList = originalInput.files
    if (!fileList || fileList.length === 0) return

    const arrayLength = fileList.length
    if (arrayLength > maxFiles || fileCount + arrayLength > maxFiles) {
      const maxFilesMsg = this.hasMaxFilesMessageValue
      ? this.maxFilesMessageValue.replace('%{count}', String(maxFiles))
      : `You can only upload ${maxFiles} files at a time.`
      alert(maxFilesMsg)
      originalInput.value = ''
      return
    }

    const maxSize = this.hasMaxTusSizeValue ? this.maxTusSizeValue : 0
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
      this.addFileViaTus(originalInput, originalParent, arrayLength, maxFiles)
      return
    }

    for (let i = 0; i < arrayLength; i++) {
      fileCount += 1
      const file = originalInput.files[i]
      const fileName = file.name + ' (' + formatBytes(file.size) + ')'

      const li = document.createElement("li")
      li.classList.add("list-group-item", "selected-file", "list-group-item-primary", "small")
      li.append(originalInput)
      const trashLink = document.createElement("a")
      trashLink.setAttribute("data-action", "multi-upload#removeFile")
      trashLink.setAttribute("href", "#")
      trashLink.innerHTML = "<em class=\"bi bi-trash me-2\"></em>"
      li.appendChild(trashLink)
      li.appendChild(document.createTextNode(fileName))
      this.filesTarget.append(li)
    }

    originalInput.removeAttribute('required')
    this.updateFilesFooter()

    const newInput = originalInput.cloneNode()
    newInput.value = ""
    originalParent.append(newInput)
  }

  addFileViaTus(originalInput, _originalParent, arrayLength, _maxFiles) {
    const controller = this
    const endpoint = this.tusEndpointValue || '/uploads'
    const inputName = this.filesInputNameValue || 'push[files][]'
    const files = originalInput.files
    const tusTpl = document.getElementById("tus-upload-row-template")
    const selectedTpl = document.getElementById("selected-file-row-template")
    const bars = document.getElementById("progress-bars")

    for (let i = 0; i < arrayLength; i++) {
      fileCount += 1
      const file = files[i]
      const id = ++this.tusUploadId
      const fileName = file.name + ' (' + formatBytes(file.size) + ')'

      let li, progressBar, pauseBtn, resumeBtn
      if (tusTpl && bars) {
        const row = tusTpl.content.cloneNode(true)
        li = row.querySelector("li")
        li.id = `progress-${id}`
        row.querySelector(".tus-row-name").textContent = file.name
        progressBar = row.querySelector(".tus-row-progress-bar")
        progressBar.id = `tus-upload-${id}`
        progressBar.setAttribute("aria-label", file.name)
        pauseBtn = row.querySelector(".tus-row-pause")
        resumeBtn = row.querySelector(".tus-row-resume")
        setTusProgressDetails(progressBar, 0, file.size)
        bars.append(row)
      } else {
        li = document.createElement("li")
        li.id = `progress-${id}`
        li.className = "list-group-item list-group-item-primary small tus-upload-row d-flex flex-wrap align-items-center gap-2"
        const nameSpan = document.createElement("span")
        nameSpan.className = "text-truncate small"
        nameSpan.style.minWidth = "6em"
        nameSpan.textContent = file.name
        li.appendChild(document.createElement("span")).className = "badge bg-info text-nowrap"
        li.lastElementChild.textContent = "Resumable"
        li.appendChild(nameSpan)
        const progressWrap = document.createElement("div")
        progressWrap.className = "progress flex-grow-1"
        progressWrap.style = "height: 1.5rem; min-width: 80px"
        progressBar = document.createElement("div")
        progressBar.className = "progress-bar progress-bar-striped progress-bar-animated"
        progressBar.setAttribute("role", "progressbar")
        progressBar.setAttribute("aria-label", file.name)
        progressBar.id = `tus-upload-${id}`
        progressWrap.appendChild(progressBar)
        li.appendChild(progressWrap)
        const sizeSpan = document.createElement("span")
        sizeSpan.className = "tus-row-size text-muted small text-nowrap"
        sizeSpan.setAttribute("aria-hidden", "true")
        li.appendChild(sizeSpan)
        pauseBtn = document.createElement("button")
        pauseBtn.type = "button"
        pauseBtn.className = "btn btn-sm btn-outline-secondary"
        pauseBtn.innerHTML = "<span class=\"bi bi-pause-fill\"></span>"
        resumeBtn = document.createElement("button")
        resumeBtn.type = "button"
        resumeBtn.className = "btn btn-sm btn-outline-success d-none"
        resumeBtn.innerHTML = "<span class=\"bi bi-play-fill\"></span>"
        li.appendChild(pauseBtn)
        li.appendChild(resumeBtn)
        setTusProgressDetails(progressBar, 0, file.size)
        bars.append(li)
      }

      const uploadStartTime = Date.now()

      const opts = {
        endpoint: endpoint,
        uploadLength: file.size,
        metadata: {
          filename: file.name,
          filetype: file.type || 'application/octet-stream'
        },
        retryDelays: [1000, 3000],
        onProgress: (bytesUploaded, bytesTotal) => {
          const finalizingLabel = this.hasFinalizingLabelValue ? this.finalizingLabelValue : null
          setTusProgressDetails(progressBar, bytesUploaded, bytesTotal, finalizingLabel)
        },
        onSuccess: (payload) => {
          const res = payload?.lastResponse
          const signedId = res?.getHeader?.('X-Signed-Id') ?? res?.getHeader?.('x-signed-id')
          if (!signedId) {
            setProgressBarError(progressBar, "Missing signed ID")
            return
          }
          li.remove()
          const elapsedMs = Date.now() - uploadStartTime
          const durationStr = formatDuration(elapsedMs)
          const uploadTimeLabel = durationStr ? `Uploaded in ${durationStr}` : ''
          if (selectedTpl) {
            const row = selectedTpl.content.cloneNode(true)
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
        },
        onError: (err) => {
          setProgressBarError(progressBar, err.message)
          fileCount -= 1
          controller.updateFilesFooter()
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
    }

    originalInput.removeAttribute('required')
    this.updateFilesFooter()
    // Clear input after a tick to avoid re-triggering 'change' in same event loop
    setTimeout(() => { originalInput.value = "" }, 0)
  }

  updateFilesFooter() {
    const footer = document.getElementById("file-count-footer")
    const maxFiles = this.maxFilesValue
    footer.innerHTML = fileCount + ` file(s) selected. You can upload up to ${maxFiles} files per push.`
  }

  removeFile(event) {
    event.preventDefault()
    const listItem = event.target.closest('li')
    if (!listItem || !listItem.parentNode) return

    listItem.remove()
    fileCount -= 1
    this.updateFilesFooter()
  }
}