import { Controller } from "@hotwired/stimulus"

// Escape in the note editor does the same as its Cancel link: closes the
// editor without saving and puts focus back on the note's button.
export default class extends Controller {
  static targets = [ "cancel" ]

  cancel(event) {
    event.preventDefault()
    this.cancelTarget.click()
  }
}
