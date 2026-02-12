import * as ActiveStorage from "@rails/activestorage"

import { Controller } from "@hotwired/stimulus"

let fileCount = 0
let tusUploadId = 0

function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const dm = decimals < 0 ? 0 : decimals
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i]
}

// Shared progress bar API for both direct and TUS uploads
function setProgressBarProgress(el, percent) {
  if (!el) return
  el.setAttribute('aria-valuenow', String(percent))
  el.style.width = percent + '%'
}

function setProgressBarError(el, message) {
  if (!el) return
  el.classList.add('bg-danger')
  el.setAttribute('aria-label', message || 'Upload failed')
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
    maxDirectSize: Number,
    fileTooLargeMessage: String,
    maxFilesMessage: String,
    tusEnabled: Boolean,
    tusEndpoint: String,
    filesInputName: String,
  }

  connect() {
    // Reset the file count
    fileCount = 0

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

    if (this.tusEnabledValue && typeof window.tus !== 'undefined') {
      this.addFileViaTus(originalInput, originalParent, arrayLength, maxFiles)
      return
    }

    const maxDirectSize = this.hasMaxDirectSizeValue ? this.maxDirectSizeValue : 0
    for (let i = 0; i < arrayLength; i++) {
      const file = originalInput.files[i]
      if (maxDirectSize > 0 && file.size > maxDirectSize) {
        const msg = this.hasFileTooLargeMessageValue
          ? this.fileTooLargeMessageValue.replace('%{filename}', file.name).replace('%{size}', formatBytes(maxDirectSize))
          : `"${file.name}" is too large. Max size per file is ${formatBytes(maxDirectSize)} when resumable upload is disabled.`
        alert(msg)
        originalInput.value = ''
        return
      }
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
      const id = ++tusUploadId
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
        bars.append(li)
      }

      const opts = {
        endpoint: endpoint,
        uploadLength: file.size,
        metadata: {
          filename: file.name,
          filetype: file.type || 'application/octet-stream'
        },
        retryDelays: [1000, 3000],
        onProgress: (bytesUploaded, bytesTotal) => {
          const pct = bytesTotal > 0 ? Math.round((bytesUploaded / bytesTotal) * 100) : 0
          setProgressBarProgress(progressBar, pct)
        },
        onSuccess: (payload) => {
          const signedId = payload?.lastResponse?.getHeader?.('X-Signed-Id')
          if (!signedId) {
            setProgressBarError(progressBar, "Missing signed ID")
            return
          }
          li.remove()
          if (selectedTpl) {
            const row = selectedTpl.content.cloneNode(true)
            const input = row.querySelector(".selected-file-input")
            input.name = inputName
            input.value = signedId
            row.querySelector(".selected-file-name").textContent = fileName
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
            selectedFile.appendChild(document.createTextNode(fileName))
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
        opts.uploadUrl = uploadUrl
        upload = new window.tus.Upload(file, opts)
        upload.start()
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
