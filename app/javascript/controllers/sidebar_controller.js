import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "backdrop", "panel"]

  open() {
    this.overlayTarget.classList.remove("hidden")
    // Trigger reflow before adding transition classes
    requestAnimationFrame(() => {
      this.backdropTarget.classList.add("opacity-100")
      this.backdropTarget.classList.remove("opacity-0")
      this.panelTarget.classList.add("translate-x-0")
      this.panelTarget.classList.remove("-translate-x-full")
    })
  }

  close() {
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0")
    this.panelTarget.classList.remove("translate-x-0")
    this.panelTarget.classList.add("-translate-x-full")

    // Wait for transition to finish before hiding overlay
    setTimeout(() => {
      this.overlayTarget.classList.add("hidden")
    }, 300)
  }

  toggle() {
    if (this.overlayTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }
}
