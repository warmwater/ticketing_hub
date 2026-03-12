import { Controller } from "@hotwired/stimulus"

// On mobile, this controller syncs mobile quantity inputs to hidden ticket_quantities fields
// so the same form works on both desktop and mobile without duplicate name conflicts.
export default class extends Controller {
  static targets = ["input"]

  connect() {
    // On mobile, the desktop inputs are hidden (sm:block = hidden on mobile)
    // This controller handles copying mobile values into the real desktop inputs on submit
    this.element.closest("form")?.addEventListener("submit", this.syncValues.bind(this))
  }

  disconnect() {
    this.element.closest("form")?.removeEventListener("submit", this.syncValues.bind(this))
  }

  syncValues(event) {
    // Only sync if the mobile container is visible
    if (this.element.offsetParent === null) return

    this.inputTargets.forEach(input => {
      const ticketId = input.dataset.ticketId
      const desktopInput = this.element.closest("form")?.querySelector(
        `input[name="ticket_quantities[${ticketId}]"]`
      )
      if (desktopInput) {
        desktopInput.value = input.value
      }
    })
  }
}
