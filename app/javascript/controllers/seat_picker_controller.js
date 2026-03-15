import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "counter", "hiddenInputs", "submitBtn", "status"]
  static values = {
    eventId: Number,
    allSelectedText: { type: String, default: "All seats selected! Ready to place order." },
    selectMoreText: { type: String, default: "Select %{count} more seat(s) to continue" },
    selectSeatsHintText: { type: String, default: "Select your seats to continue" },
    seatTakenNoticeText: { type: String, default: "A seat you selected was just taken by another buyer. Please choose a different seat." },
    seatHeldNoticeText: { type: String, default: "This seat is temporarily held by another buyer. Please choose a different seat." }
  }

  connect() {
    // Track selected seats per ticket type: { ticketTypeId: Set(seatId, ...) }
    this.selections = {}
    this.requirements = {}
    // Map seatId → holdId so we can release holds on deselect / page leave
    this.holds = {}

    this.sectionTargets.forEach(section => {
      const ttId    = section.dataset.sectionTicketTypeId
      const required = parseInt(section.dataset.sectionRequired, 10)
      this.requirements[ttId] = required
      this.selections[ttId]   = new Set()
    })

    // Watch for Turbo Stream replacements — if a seat that the user already
    // selected gets replaced (confirmed by another buyer), drop it from the
    // local selection and alert them.
    //
    // However, when the CURRENT user holds a seat, the server also broadcasts
    // _held_seat.html.erb which replaces the button for everyone — including
    // this user. We must detect that case (seat is in this.holds) and re-apply
    // the selected styling instead of dropping the selection.
    this.observer = new MutationObserver((mutations) => {
      let needsUpdate = false
      for (const mutation of mutations) {
        for (const removedNode of mutation.removedNodes) {
          if (removedNode.nodeType !== Node.ELEMENT_NODE) continue
          const seatId = removedNode.dataset?.seatId
          const ttId   = removedNode.dataset?.ticketTypeId
          if (!seatId) continue

          // If this seat is held by the current user, the Turbo Stream
          // replacement is just our own hold broadcast bouncing back.
          // Re-apply selected styling to the new element.
          if (seatId && this.holds[seatId]) {
            const newEl = document.getElementById(removedNode.id)
            if (newEl) {
              this._restyleAsSelected(newEl, seatId, ttId)
            }
            continue
          }

          if (ttId && this.selections[ttId]?.has(seatId)) {
            this.selections[ttId].delete(seatId)
            delete this.holds[seatId]
            needsUpdate = true
          }
        }
      }
      if (needsUpdate) {
        this.updateUI()
        this.showNotice(this.seatTakenNoticeTextValue, "red")
      }
    })
    this.observer.observe(this.element, { childList: true, subtree: true })

    // Release all holds when the user navigates away without completing the order
    this._boundBeforeUnload = this.releaseAllHolds.bind(this)
    window.addEventListener("beforeunload", this._boundBeforeUnload)

    this.updateUI()
  }

  disconnect() {
    if (this.observer) { this.observer.disconnect(); this.observer = null }
    window.removeEventListener("beforeunload", this._boundBeforeUnload)
    // Release holds synchronously when Turbo navigates away (SPA-style)
    this.releaseAllHolds()
  }

  // ── Seat toggle ───────────────────────────────────────────────────────────

  async toggleSeat(event) {
    const btn    = event.currentTarget
    const seatId = btn.dataset.seatId
    const ttId   = btn.dataset.ticketTypeId
    const selected = this.selections[ttId]

    if (selected.has(seatId)) {
      // ── Deselect: release the hold ──────────────────────────────────────
      const holdId = this.holds[seatId]
      if (holdId) {
        await this.releaseHold(holdId)
        delete this.holds[seatId]
      }
      selected.delete(seatId)
      // Restyle immediately (the server broadcast will replace the element
      // back to an available_seat button, but we want instant feedback).
      btn.classList.remove("bg-indigo-500", "ring-indigo-600", "hover:bg-indigo-400",
                           "bg-amber-400", "ring-amber-500", "cursor-not-allowed")
      btn.classList.add("bg-emerald-500", "ring-emerald-600", "hover:bg-emerald-400")
    } else {
      // ── Select: request a hold first ────────────────────────────────────
      if (selected.size >= this.requirements[ttId]) return

      const result = await this.requestHold(seatId)

      if (result === "taken") {
        this.showNotice(this.seatTakenNoticeTextValue, "red"); return
      }
      if (result === "held") {
        this.showNotice(this.seatHeldNoticeTextValue, "amber"); return
      }
      // result is the numeric holdId
      this.holds[seatId] = result
      selected.add(seatId)
      btn.classList.remove("bg-emerald-500", "ring-emerald-600", "hover:bg-emerald-400")
      btn.classList.add("bg-indigo-500", "ring-indigo-600", "hover:bg-indigo-400")
    }

    this.updateUI()
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────

  async requestHold(seatId) {
    try {
      const res = await fetch("/seat_holds", {
        method: "POST",
        headers: this.jsonHeaders(),
        body: JSON.stringify({ seat_id: seatId, event_id: this.eventIdValue })
      })
      if (res.ok) {
        const data = await res.json()
        return data.hold_id   // success → numeric hold ID
      }
      const err = await res.json().catch(() => ({}))
      return err.error || "held"  // "taken" | "held"
    } catch {
      return "held"
    }
  }

  async releaseHold(holdId) {
    try {
      await fetch(`/seat_holds/${holdId}`, {
        method: "DELETE",
        headers: this.jsonHeaders()
      })
    } catch { /* server auto-expires holds, safe to ignore */ }
  }

  releaseAllHolds() {
    // Fire-and-forget on page unload. `keepalive: true` lets the request
    // survive the page teardown (Fetch keepalive limit: 64 KB).
    Object.entries(this.holds).forEach(([_seatId, holdId]) => {
      fetch(`/seat_holds/${holdId}`, {
        method: "DELETE",
        headers: this.jsonHeaders(),
        keepalive: true
      }).catch(() => {})
    })
    this.holds = {}
  }

  jsonHeaders() {
    return {
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content ?? "",
      "Accept": "application/json"
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  updateUI() {
    this.counterTargets.forEach(counter => {
      const ttId = counter.dataset.counterFor
      counter.textContent = this.selections[ttId]?.size ?? 0
    })

    this.hiddenInputsTarget.innerHTML = ""
    Object.entries(this.selections).forEach(([ttId, seats]) => {
      seats.forEach(seatId => {
        const input = document.createElement("input")
        input.type  = "hidden"
        input.name  = `seat_selections[${ttId}][]`
        input.value = seatId
        this.hiddenInputsTarget.appendChild(input)
      })
    })

    const allMet = Object.entries(this.requirements).every(([ttId, required]) =>
      this.selections[ttId]?.size === required
    )
    this.submitBtnTarget.disabled = !allMet

    if (allMet) {
      this.statusTarget.textContent = this.allSelectedTextValue
      this.statusTarget.classList.remove("text-gray-500")
      this.statusTarget.classList.add("text-green-600", "font-medium")
    } else {
      const remaining = Object.entries(this.requirements).reduce((sum, [ttId, required]) =>
        sum + (required - (this.selections[ttId]?.size ?? 0)), 0
      )
      this.statusTarget.textContent = this.selectMoreTextValue.replace("%{count}", remaining)
      this.statusTarget.classList.remove("text-green-600", "font-medium")
      this.statusTarget.classList.add("text-gray-500")
    }
  }

  showNotice(message, color = "amber") {
    const palette = {
      amber: "bg-amber-100 border-amber-300 text-amber-800",
      red:   "bg-red-100   border-red-300   text-red-800"
    }
    const notice = document.createElement("div")
    notice.className = `fixed top-4 right-4 z-50 rounded-lg border px-4 py-3 text-sm shadow-lg transition-opacity duration-500 ${palette[color] ?? palette.amber}`
    notice.textContent = message
    document.body.appendChild(notice)
    setTimeout(() => {
      notice.classList.add("opacity-0")
      setTimeout(() => notice.remove(), 500)
    }, 4000)
  }

  // Re-style a Turbo-replaced element (div or button) as "selected" (indigo).
  // Also re-attach the click action so the user can deselect it.
  _restyleAsSelected(el, seatId, ttId) {
    el.classList.remove(
      "bg-amber-400", "ring-amber-500", "cursor-not-allowed",
      "bg-emerald-500", "ring-emerald-600", "hover:bg-emerald-400",
      "bg-slate-400", "ring-slate-500"
    )
    el.classList.add("bg-indigo-500", "ring-indigo-600", "hover:bg-indigo-400", "cursor-pointer")

    // If the replacement is a <div> (held_seat partial), convert behaviour
    // so the user can still click to deselect.
    el.style.cursor = "pointer"
    el.dataset.seatId = seatId
    if (ttId) el.dataset.ticketTypeId = ttId
    el.dataset.action = "click->seat-picker#toggleSeat"
  }

  // Kept for backward compatibility with Turbo Stream mutation observer
  showSeatTakenNotice() { this.showNotice(this.seatTakenNoticeTextValue, "red") }
}
