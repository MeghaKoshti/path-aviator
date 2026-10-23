import { Controller } from "@hotwired/stimulus"

// Sits on the learning path partial, which the server swaps out over a Turbo
// Stream when generation finishes. Each time a new version connects it tells
// screen reader users what changed through a live region on the page.
// While a path is generating it also reloads the page now and then, in case
// the broadcast was missed (for example while the socket reconnected).
export default class extends Controller {
  static values = { status: String, message: String, refreshAfter: Number }

  connect() {
    this.announce()
    if (this.refreshAfterValue > 0) {
      this.timer = setTimeout(() => window.Turbo.visit(window.location.href, { action: "replace" }), this.refreshAfterValue)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  announce() {
    const announcer = document.getElementById("path-announcer")
    if (!announcer) return

    const previous = announcer.dataset.status
    announcer.dataset.status = this.statusValue
    // Announce status changes, and the waiting message on first load.
    if (previous ? previous !== this.statusValue : this.statusValue === "generating") {
      announcer.textContent = this.messageValue
    }
  }
}
