import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "counter", "hiddenInputs", "submitBtn", "status"]

  connect() {
    // Track selected seats per ticket type: { ticketTypeId: Set(seatId, ...) }
    this.selections = {}
    this.requirements = {}

    // Parse requirements from section elements
    this.sectionTargets.forEach(section => {
      const ttId = section.dataset.sectionTicketTypeId
      const required = parseInt(section.dataset.sectionRequired, 10)
      this.requirements[ttId] = required
      this.selections[ttId] = new Set()
    })

    this.updateUI()
  }

  toggleSeat(event) {
    const btn = event.currentTarget
    const seatId = btn.dataset.seatId
    const ttId = btn.dataset.ticketTypeId
    const selected = this.selections[ttId]

    if (selected.has(seatId)) {
      // Deselect
      selected.delete(seatId)
      btn.classList.remove("bg-indigo-500", "ring-indigo-600", "hover:bg-indigo-400")
      btn.classList.add("bg-emerald-500", "ring-emerald-600", "hover:bg-emerald-400")
    } else {
      // Check if max reached
      if (selected.size >= this.requirements[ttId]) {
        return
      }
      // Select
      selected.add(seatId)
      btn.classList.remove("bg-emerald-500", "ring-emerald-600", "hover:bg-emerald-400")
      btn.classList.add("bg-indigo-500", "ring-indigo-600", "hover:bg-indigo-400")
    }

    this.updateUI()
  }

  updateUI() {
    // Update counters
    this.counterTargets.forEach(counter => {
      const ttId = counter.dataset.counterFor
      const selected = this.selections[ttId]
      counter.textContent = selected ? selected.size : 0
    })

    // Update hidden inputs
    this.hiddenInputsTarget.innerHTML = ""
    Object.entries(this.selections).forEach(([ttId, seats]) => {
      seats.forEach(seatId => {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = `seat_selections[${ttId}][]`
        input.value = seatId
        this.hiddenInputsTarget.appendChild(input)
      })
    })

    // Check if all requirements met
    const allMet = Object.entries(this.requirements).every(([ttId, required]) => {
      return this.selections[ttId] && this.selections[ttId].size === required
    })

    this.submitBtnTarget.disabled = !allMet

    if (allMet) {
      this.statusTarget.textContent = "All seats selected! Ready to place order."
      this.statusTarget.classList.remove("text-gray-500")
      this.statusTarget.classList.add("text-green-600", "font-medium")
    } else {
      const remaining = Object.entries(this.requirements).reduce((sum, [ttId, required]) => {
        const selected = this.selections[ttId] ? this.selections[ttId].size : 0
        return sum + (required - selected)
      }, 0)
      this.statusTarget.textContent = `Select ${remaining} more seat(s) to continue`
      this.statusTarget.classList.remove("text-green-600", "font-medium")
      this.statusTarget.classList.add("text-gray-500")
    }
  }
}
