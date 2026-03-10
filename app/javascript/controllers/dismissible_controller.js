import { Controller } from "@hotwired/stimulus"

// Allows flash messages and alerts to be dismissed by clicking the close button
export default class extends Controller {
  dismiss() {
    this.element.remove()
  }
}
