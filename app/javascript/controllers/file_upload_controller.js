import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropzone", "preview"]
  static values = {
    multiple: { type: Boolean, default: false }
  }

  connect() {
    this.handleDragOver = this.handleDragOver.bind(this)
    this.handleDragLeave = this.handleDragLeave.bind(this)
    this.handleDrop = this.handleDrop.bind(this)

    this.dropzoneTarget.addEventListener("dragover", this.handleDragOver)
    this.dropzoneTarget.addEventListener("dragleave", this.handleDragLeave)
    this.dropzoneTarget.addEventListener("drop", this.handleDrop)
  }

  disconnect() {
    this.dropzoneTarget.removeEventListener("dragover", this.handleDragOver)
    this.dropzoneTarget.removeEventListener("dragleave", this.handleDragLeave)
    this.dropzoneTarget.removeEventListener("drop", this.handleDrop)
  }

  handleDragOver(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-indigo-500", "bg-indigo-50")
    this.dropzoneTarget.classList.remove("border-gray-300")
  }

  handleDragLeave(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-indigo-500", "bg-indigo-50")
    this.dropzoneTarget.classList.add("border-gray-300")
  }

  handleDrop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-indigo-500", "bg-indigo-50")
    this.dropzoneTarget.classList.add("border-gray-300")

    const files = event.dataTransfer.files
    this.inputTarget.files = files
    this.showPreviews(files)
  }

  selectFiles() {
    this.inputTarget.click()
  }

  handleFileSelect() {
    this.showPreviews(this.inputTarget.files)
  }

  showPreviews(files) {
    this.previewTarget.innerHTML = ""

    Array.from(files).forEach(file => {
      const wrapper = document.createElement("div")
      wrapper.className = "relative inline-block m-1"

      if (file.type.startsWith("image/")) {
        const img = document.createElement("img")
        img.className = "h-20 w-20 object-cover rounded-lg border border-gray-200"
        img.src = URL.createObjectURL(file)
        wrapper.appendChild(img)
      } else if (file.type.startsWith("video/")) {
        const videoIcon = document.createElement("div")
        videoIcon.className = "h-20 w-20 rounded-lg border border-gray-200 bg-gray-100 flex items-center justify-center flex-col p-1"
        videoIcon.innerHTML = `
          <svg class="h-6 w-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/>
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
          <span class="text-xs text-gray-500 truncate w-full text-center mt-1">${file.name}</span>
        `
        wrapper.appendChild(videoIcon)
      }

      const sizeLabel = document.createElement("p")
      sizeLabel.className = "text-xs text-gray-400 text-center mt-0.5"
      sizeLabel.textContent = this.formatFileSize(file.size)
      wrapper.appendChild(sizeLabel)

      this.previewTarget.appendChild(wrapper)
    })
  }

  formatFileSize(bytes) {
    if (bytes < 1024) return bytes + " B"
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB"
    return (bytes / 1048576).toFixed(1) + " MB"
  }
}
