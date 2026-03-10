import { Controller } from "@hotwired/stimulus"

// Controls the mobile hamburger menu toggle in the main navbar
export default class extends Controller {
  static targets = ["mobileMenu", "hamburger", "openIcon", "closeIcon"]

  toggleMobile() {
    const isHidden = this.mobileMenuTarget.classList.contains("hidden")

    if (isHidden) {
      this.mobileMenuTarget.classList.remove("hidden")
      this.openIconTarget.classList.add("hidden")
      this.closeIconTarget.classList.remove("hidden")
      this.hamburgerTarget.setAttribute("aria-expanded", "true")
    } else {
      this.mobileMenuTarget.classList.add("hidden")
      this.openIconTarget.classList.remove("hidden")
      this.closeIconTarget.classList.add("hidden")
      this.hamburgerTarget.setAttribute("aria-expanded", "false")
    }
  }
}
