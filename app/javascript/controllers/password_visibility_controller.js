import { Controller } from "@hotwired/stimulus"

// Lets people check what they typed in a password field.
// The button keeps one label ("Show password") and reports state via aria-pressed.
export default class extends Controller {
  static targets = [ "input", "toggle", "showIcon", "hideIcon" ]

  toggle() {
    const reveal = this.inputTarget.type === "password"
    this.inputTarget.type = reveal ? "text" : "password"
    this.toggleTarget.setAttribute("aria-pressed", String(reveal))
    this.showIconTarget.classList.toggle("hidden", reveal)
    this.hideIconTarget.classList.toggle("hidden", !reveal)
  }
}
