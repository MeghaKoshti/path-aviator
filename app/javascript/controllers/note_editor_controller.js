import { Controller } from "@hotwired/stimulus"

// Escape in the note editor does the same as its Cancel link: closes the
// editor without saving and puts focus back on the note's button.
//
// Ticking a step morphs the whole route. While the editor is open it keeps
// that morph away from its frame, so a half-written note survives. This only
// affects morphs: leaving the page and coming back shows the saved note.
export default class extends Controller {
  static targets = [ "cancel" ]

  cancel(event) {
    event.preventDefault()
    this.cancelTarget.click()
  }

  keepDraft(event) {
    if (event.target === this.element.closest("turbo-frame")) event.preventDefault()
  }
}
