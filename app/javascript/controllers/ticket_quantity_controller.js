import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "total", "itemTotal"]
  static values = { prices: Object }

  connect() {
    this.updateTotal()
  }

  updateTotal() {
    let total = 0
    this.inputTargets.forEach((input) => {
      const quantity = parseInt(input.value) || 0
      const price = parseFloat(input.dataset.price) || 0
      const itemTotal = quantity * price

      const itemTotalEl = document.getElementById(`item-total-${input.dataset.ticketTypeId}`)
      if (itemTotalEl) {
        itemTotalEl.textContent = `$${itemTotal.toFixed(2)}`
      }

      total += itemTotal
    })

    if (this.hasTotalTarget) {
      this.totalTarget.textContent = `$${total.toFixed(2)}`
    }
  }
}
