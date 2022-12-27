import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

addEventListener("direct-upload:initialize", event => {
    const { target, detail } = event
    const { id, file } = detail

    const files = document.getElementById("selected-files")
    files.style.display = "none"

    const bars = document.getElementById("progress-bars")
    const li = document.createElement("li")
    li.classList = 'list-group-item list-group-item-primary small'

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