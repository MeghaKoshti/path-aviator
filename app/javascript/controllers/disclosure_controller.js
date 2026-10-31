import { Controller } from "@hotwired/stimulus"

// Shows and hides a panel (mobile nav, account menu).
// Closes on Escape or a click outside, and keeps aria-expanded in sync.
export default class extends Controller {
  static targets = [ "button", "panel" ]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.closeOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  toggle() {
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.panelTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  closeWithKeyboard(event) {
    if (event.key !== "Escape" || !this.isOpen) return
    this.close()
    this.buttonTarget.focus()
  }

  closeOnOutsideClick(event) {
    if (this.isOpen && !this.element.contains(event.target)) this.close()
  }

  get isOpen() {
    return !this.panelTarget.hidden
  }
}
