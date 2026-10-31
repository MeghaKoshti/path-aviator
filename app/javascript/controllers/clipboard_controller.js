import { Controller } from "@hotwired/stimulus"

// Copies the share link and confirms it in a status message that screen
// readers announce. The server sends the link's path; the origin comes from
// this page, so the link is right even when the panel was rendered by a
// background job that doesn't know the host.
export default class extends Controller {
  static targets = [ "source", "status" ]
  static values = { path: String }

  connect() {
    if (this.hasPathValue) this.sourceTarget.value = new URL(this.pathValue, window.location.origin).href
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.report("Link copied.")
    } catch {
      // No clipboard access: select the link so it can be copied by hand.
      this.select()
      this.report("Couldn’t copy. The link is selected, so copy it with your keyboard.")
    }
  }

  select() {
    this.sourceTarget.select()
  }

  report(message) {
    this.statusTarget.textContent = message
    clearTimeout(this.timer)
    this.timer = setTimeout(() => { this.statusTarget.textContent = "" }, 5000)
  }
}
