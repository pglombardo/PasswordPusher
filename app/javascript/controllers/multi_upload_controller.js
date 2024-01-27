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

export default class extends Controller {
  // Target contains the selected file list
  static targets = ["files"]

  static values = {
    maxFiles: Number,
  }

  connect() {
    // Reset the file count
    fileCount = 0

    ActiveStorage.start()

    addEventListener("direct-upload:initialize", event => {
      const { target, detail } = event
      const { id, file } = detail

      const preExistingBar = document.getElementById(`progress-${id}`)
      if (preExistingBar) {
        preExistingBar.remove()
      }

      const files = document.getElementById("selected-files")
      files.style.display = "none"

      const bars = document.getElementById("progress-bars")
      const li = document.createElement("li")
      li.classList = 'list-group-item list-group-item-primary small'
      li.setAttribute("id", `progress-${id}`)

      const progress = document.createElement("div")
      progress.classList = 'progress'
      progress.style = 'height: 1.5rem'

      const progressBar = document.createElement("div")
      progressBar.classList = 'progress-bar progress-bar-striped progress-bar-animated'
      progressBar.setAttribute("role", "progressbar")
      progressBar.setAttribute("aria-label", file.name)
      progressBar.setAttribute("aria-valuenow", "0")
      progressBar.setAttribute("aria-valuemin", "0")
      progressBar.setAttribute("aria-valuemax", "100")
      progressBar.setAttribute("style", "width: 0%")
      progressBar.setAttribute("id", `direct-upload-${id}`)
      progressBar.append(file.name)

      progress.append(progressBar)
      li.append(progress)
      bars.append(li)
    })

    addEventListener("direct-upload:start", event => {
      const { id } = event.detail
      const element = document.getElementById(`direct-upload-${id}`)
      element.setAttribute("aria-valuenow", "0");
    })

    addEventListener("direct-upload:progress", event => {
      const { id, progress } = event.detail
      const progressElement = document.getElementById(`direct-upload-${id}`)
      progressElement.setAttribute("aria-valuenow", progress);
      progressElement.setAttribute("style", "width: " + progress + "%");
    })

    addEventListener("direct-upload:error", event => {
      event.preventDefault()
      const { id, error } = event.detail
      const element = document.getElementById(`direct-upload-${id}`)
      element.classList.add("bg-danger")
      element.setAttribute("aria-label", error)
    })

    addEventListener("direct-upload:end", event => {
      const { id } = event.detail
      const element = document.getElementById(`direct-upload-${id}`)
      element.setAttribute("aria-label", "Complete")
    })
  }

  addFile(event) {
    const originalInput = event.target
    const originalParent = originalInput.parentNode
    const maxFiles = this.maxFilesValue

    let arrayLength = event.target.files.length
    if (arrayLength > maxFiles || fileCount + arrayLength > maxFiles) {
      alert(`You can only upload ${maxFiles} files at a time.`)
      event.preventDefault()
      event.stopPropagation()
      originalInput.value = ''
      return
    }

    for (let i = 0; i < arrayLength; i++) {
      fileCount += 1

      let fileName = originalInput.files[i].name + ' (' + formatBytes(originalInput.files[i].size) + ')'

      const selectedFile = document.createElement("li")
      selectedFile.classList = "list-group-item selected-file list-group-item-primary small"
      selectedFile.append(originalInput)

      let trashIcon = document.createElement("em")
      trashIcon.classList = 'bi bi-trash me-2'

      let trashLink = document.createElement("a")
      trashLink.setAttribute('data-action', 'multi-upload#removeFile')
      trashLink.appendChild(trashIcon)
      selectedFile.appendChild(trashLink)

      let textElement = document.createTextNode(fileName);
      selectedFile.appendChild(textElement)

      this.filesTarget.append(selectedFile)
    }

    originalInput.removeAttribute('required')
    this.updateFilesFooter()

    const newInput = originalInput.cloneNode()
    newInput.value = ""
    originalParent.append(newInput)
  }

  updateFilesFooter() {
    const footer = document.getElementById("file-count-footer")
    const maxFiles = this.maxFilesValue
    footer.innerHTML = fileCount + ` file(s) selected. You can upload up to ${maxFiles} files per push.`
  }

  removeFile(event) {
    const listItem = event.target.parentNode.parentNode
    const list = listItem.parentNode

    list.removeChild(listItem)
    fileCount -= 1
    this.updateFilesFooter()
  }
}
