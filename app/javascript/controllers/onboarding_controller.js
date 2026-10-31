import { Controller } from "@hotwired/stimulus"

// Shows the onboarding form one question at a time.
// Without JavaScript every step is visible and the form submits as one page.
export default class extends Controller {
  static targets = [ "form", "step", "waypoint", "back", "next", "submit", "status", "suggestions" ]

  // Runs on first load and again when a failed submit re-renders the form in the frame.
  formTargetConnected(form) {
    if (this.hasSuggestionsTarget) this.suggestionsTarget.hidden = false
    const start = form.dataset.startStep
    this.show(start ? Number(start) : 0, { focus: Boolean(start) })
  }

  next() {
    if (this.currentStepIsValid()) this.show(this.index + 1, { focus: true })
  }

  back() {
    this.show(this.index - 1, { focus: true })
  }

  // Pressing Enter on an early step moves forward instead of submitting half a form.
  submit(event) {
    if (this.isLastStep) return
    event.preventDefault()
    this.next()
  }

  suggest(event) {
    const input = this.stepTargets[0].querySelector("input")
    input.value = event.currentTarget.dataset.topic
    input.focus()
  }

  // A successful submit redirects to the path page, which has no "onboarding" frame.
  followRedirect(event) {
    event.preventDefault()
    event.detail.visit(event.detail.response.url)
  }

  show(index, { focus = false } = {}) {
    this.index = Math.max(0, Math.min(index, this.stepTargets.length - 1))

    this.stepTargets.forEach((step, i) => { step.hidden = i !== this.index })
    this.waypointTargets.forEach((waypoint, i) => {
      waypoint.dataset.state = i < this.index ? "done" : i === this.index ? "current" : "todo"
      if (i === this.index) waypoint.setAttribute("aria-current", "step")
      else waypoint.removeAttribute("aria-current")
    })

    this.backTarget.hidden = this.index === 0
    this.nextTarget.hidden = this.isLastStep
    this.submitTarget.hidden = !this.isLastStep

    const step = this.stepTargets[this.index]
    this.statusTarget.textContent = `Step ${this.index + 1} of ${this.stepTargets.length}: ${step.dataset.title}`
    if (focus) this.focusFirstField(step)
  }

  currentStepIsValid() {
    const fields = this.stepTargets[this.index].querySelectorAll("input, textarea, select")
    const invalid = Array.from(fields).find((field) => !field.checkValidity())
    if (invalid) invalid.reportValidity()
    return !invalid
  }

  focusFirstField(step) {
    const field = step.querySelector("input:checked, [aria-invalid=true]") || step.querySelector("input, textarea, select")
    field?.focus()
  }

  get isLastStep() {
    return this.index === this.stepTargets.length - 1
  }
}
