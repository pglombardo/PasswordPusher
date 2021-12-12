import { Controller } from "@hotwired/stimulus"

function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

export default class extends Controller {
  // filesTarget is going to contain the list of input elements we've added
  // files to - in other words, these are the input elements that we're going
  // to submit.
  static targets = ["files"]

  addFile(event) {

    window.blah = event

    // Grab some references for later
    const originalInput = event.target
    const originalParent = originalInput.parentNode

    var arrayLength = event.target.files.length;
    for (var i = 0; i < arrayLength; i++) {
      var fileName = originalInput.files[i].name + ' (' + formatBytes(originalInput.files[i].size) + ')'
  
      const selectedFile = document.createElement("li")
      selectedFile.classList = "list-group-item selected-file list-group-item-primary"
      selectedFile.append(originalInput)

      var trashIcon = document.createElement("em")
      trashIcon.classList = 'bi bi-trash me-2'
      
      var trashLink = document.createElement("a")
      // trashLink.href = '#'
      trashLink.setAttribute('data-action', 'multi-upload#removeFile')
      trashLink.appendChild(trashIcon)
      selectedFile.appendChild(trashLink)
    
      // Create label (the visible part of the new input element) with the name of
      // the selected file.
      var textElement = document.createTextNode(fileName);
      selectedFile.appendChild(textElement);
    
      // Add the selected file to the list of selected files
      this.filesTarget.append(selectedFile)
    }
    
    // Create a new input field to use going forward
    const newInput = originalInput.cloneNode()
  
    // Clear the filelist - some browsers maintain the filelist when cloning,
    // others don't
    newInput.value = ""
  
    // Add it to the DOM where the original input was
    originalParent.append(newInput)
  }
  
  removeFile(event) {

    window.fdsa = event

    // Grab some references for later
    const listItem = event.target.parentNode.parentNode
    const list = listItem.parentNode

    list.removeChild(listItem)
  }
  

}
