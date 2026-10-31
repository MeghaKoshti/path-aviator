import { Controller } from "@hotwired/stimulus"

// Monthly/yearly and rupee/dollar toggles for prices. The server renders every
// variant and the right one visible; this only flips `hidden`, aria-pressed and
// the checkout form's hidden fields. A currency choice is kept in a cookie so the
// server shows it next time.
export default class extends Controller {
  static targets = [ "variant", "intervalButton", "currencyButton", "intervalField", "currencyField" ]
  static values = { interval: String, currency: String, chosen: Boolean }

  connect() {
    if (!this.chosenValue && this.inIndia()) this.currencyValue = "inr"
  }

  chooseInterval(event) {
    this.intervalValue = event.currentTarget.dataset.value
  }

  chooseCurrency(event) {
    this.currencyValue = event.currentTarget.dataset.value
    document.cookie = `currency=${this.currencyValue}; path=/; max-age=31536000; SameSite=Lax`
  }

  intervalValueChanged() { this.render() }
  currencyValueChanged() { this.render() }

  render() {
    const current = { interval: this.intervalValue, currency: this.currencyValue }
    this.variantTargets.forEach(el => {
      el.hidden = Object.keys(current).some(key => el.dataset[key] && el.dataset[key] !== current[key])
    })
    this.intervalButtonTargets.forEach(b => b.setAttribute("aria-pressed", b.dataset.value === current.interval))
    this.currencyButtonTargets.forEach(b => b.setAttribute("aria-pressed", b.dataset.value === current.currency))
    this.intervalFieldTargets.forEach(f => { f.value = current.interval })
    this.currencyFieldTargets.forEach(f => { f.value = current.currency })
  }

  inIndia() {
    const zone = Intl.DateTimeFormat().resolvedOptions().timeZone
    return zone === "Asia/Kolkata" || zone === "Asia/Calcutta"
  }
}
