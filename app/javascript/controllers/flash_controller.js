import { Controller } from "@hotwired/stimulus"

// Auto-dismisses a toast after `dismissAfter` ms (0 = stay until closed).
// Hovering or focusing the toast pauses the timer so it can be read.
export default class extends Controller {
  static values = { dismissAfter: Number }

  connect() {
    this.resume()
  }

  disconnect() {
    this.pause()
  }

  pause() {
    clearTimeout(this.timer)
  }

  resume() {
    if (this.dismissAfterValue > 0) {
      this.pause()
      this.timer = setTimeout(() => this.dismiss(), this.dismissAfterValue)
    }
  }

  dismiss() {
    this.element.remove()
  }
}
