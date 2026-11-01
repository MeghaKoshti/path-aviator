import { Controller } from "@hotwired/stimulus"

// Fills a hidden field with the browser's time zone ("Asia/Kolkata") so a
// new account's week and streak start at local midnight. Without JavaScript
// the field stays empty and the account uses UTC until changed in Settings.
export default class extends Controller {
  connect() {
    try {
      this.element.value = Intl.DateTimeFormat().resolvedOptions().timeZone || ""
    } catch {
      // Very old browsers: keep the server default.
    }
  }
}
