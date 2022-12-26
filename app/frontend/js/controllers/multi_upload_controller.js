import { Controller } from "@hotwired/stimulus"

var fileCount = 0

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

  addFile(event) {
    const originalInput = event.target
    const originalParent = originalInput.parentNode

    originalInput.removeAttribute('required')

    var arrayLength = event.target.files.length
    for (var i = 0; i < arrayLength; i++) {
      if (fileCount >= 10) {
        this.updateFilesFooter()
        alert("You can only upload 10 files at a time.")
        return
      }
      fileCount += 1

      var fileName = originalInput.files[i].name + ' (' + formatBytes(originalInput.files[i].size) + ')'

      const selectedFile = document.createElement("li")
      selectedFile.classList = "list-group-item selected-file list-group-item-primary small"
      selectedFile.append(originalInput)

      var trashIcon = document.createElement("em")
      trashIcon.classList = 'bi bi-trash me-2'

      var trashLink = document.createElement("a")
      trashLink.setAttribute('data-action', 'multi-upload#removeFile')
      trashLink.appendChild(trashIcon)
      selectedFile.appendChild(trashLink)

      var textElement = document.createTextNode(fileName);
      selectedFile.appendChild(textElement)

      this.filesTarget.append(selectedFile)
    }

    this.updateFilesFooter()

    const newInput = originalInput.cloneNode()
    newInput.value = ""
    originalParent.append(newInput)
  }

  updateFilesFooter() {
    const footer = document.getElementById("file-count-footer")
    footer.innerHTML = fileCount + " file(s) selected. You can upload up to 10 files per push."
  }

  removeFile(event) {
    const listItem = event.target.parentNode.parentNode
    const list = listItem.parentNode

    list.removeChild(listItem)
    fileCount -= 1
  }

}
