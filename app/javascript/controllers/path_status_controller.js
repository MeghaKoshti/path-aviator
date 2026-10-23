import { Controller } from "@hotwired/stimulus"

// Sits on the learning path partial, which the server swaps out over a Turbo
// Stream when generation finishes. Each time a new version connects it tells
// screen reader users what changed through a live region on the page.
// While a path is generating it also reloads the page now and then, in case
// the broadcast was missed (for example while the socket reconnected).
export default class extends Controller {
  static values = { status: String, message: String, refreshAfter: Number, statusUrl: String }

  connect() {
    this.announce()
    if (this.statusValue === "generating") this.recheckWhenSubscribed()
    if (this.refreshAfterValue > 0) {
      this.timer = setTimeout(() => window.Turbo.visit(window.location.href, { action: "replace" }), this.refreshAfterValue)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
    this.observer?.disconnect()
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

  // A job that finishes after this page was rendered but before the stream
  // subscribed (or while it was reconnecting) broadcasts to nobody. So each
  // time the stream (re)connects, ask the server whether the status moved on.
  recheckWhenSubscribed() {
    const source = document.querySelector("turbo-cable-stream-source")
    if (!source || !this.hasStatusUrlValue) return

    if (source.hasAttribute("connected")) this.recheck()
    this.observer = new MutationObserver(() => {
      if (source.hasAttribute("connected")) this.recheck()
    })
    this.observer.observe(source, { attributes: true, attributeFilter: [ "connected" ] })
  }

  async recheck() {
    const response = await fetch(this.statusUrlValue, { headers: { Accept: "application/json" } })
    if (!response.ok) return

    const { status } = await response.json()
    if (status !== this.statusValue && this.element.isConnected) {
      window.Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
