import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    eventId: Number,
    pollInterval: { type: Number, default: 5000 },
    admitted: { type: Boolean, default: false },
    expiresAt: String
  }

  static targets = ["position", "total", "countdown", "status"]

  connect() {
    if (!this.admittedValue) {
      this.startPolling()
    } else if (this.expiresAtValue) {
      this.startCountdown()
    }
  }

  disconnect() {
    this.stopPolling()
    this.stopCountdown()
  }

  startPolling() {
    this.poll()
    this.pollTimer = setInterval(() => this.poll(), this.pollIntervalValue)
  }

  stopPolling() {
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
  }

  async poll() {
    try {
      const response = await fetch(`/events/${this.eventIdValue}/waiting_room/status`, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const contentType = response.headers.get("content-type")
        if (contentType && contentType.includes("text/vnd.turbo-stream.html")) {
          const html = await response.text()
          Turbo.renderStreamMessage(html)
        }
      }
    } catch (error) {
      console.error("Waiting room poll error:", error)
    }
  }

  startCountdown() {
    if (!this.expiresAtValue) return

    const expiryTime = new Date(this.expiresAtValue)

    this.updateCountdown(expiryTime)
    this.countdownTimer = setInterval(() => {
      this.updateCountdown(expiryTime)
    }, 1000)
  }

  stopCountdown() {
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer)
      this.countdownTimer = null
    }
  }

  updateCountdown(expiryTime) {
    const now = new Date()
    const remaining = Math.max(0, expiryTime - now)

    if (remaining === 0) {
      this.stopCountdown()
      window.location.reload()
      return
    }

    const minutes = Math.floor(remaining / 60000)
    const seconds = Math.floor((remaining % 60000) / 1000)

    if (this.hasCountdownTarget) {
      this.countdownTarget.textContent = `${minutes}:${seconds.toString().padStart(2, "0")}`
    }
  }
}
