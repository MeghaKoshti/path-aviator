import { Controller } from "@hotwired/stimulus"

// Turbo disables a form's button while its request runs, and a disabled
// button loses focus. Once the request ends, put focus back on the button
// that was pressed (looked up by id, since a morph may have updated it), so
// keyboard and screen reader users stay on the step they just ticked.
export default class extends Controller {
  remember(event) {
    this.submitterId = event.detail.formSubmission.submitter?.id
  }

  restore() {
    if (this.submitterId) document.getElementById(this.submitterId)?.focus()
    this.submitterId = null
  }
}
