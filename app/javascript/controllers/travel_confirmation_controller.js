import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    from: String,
    to: String,
    cost: Number
  }

  confirm(event) {
    const message = `Travel from ${this.fromValue} to ${this.toValue} for $${this.costValue}?`

    if (!window.confirm(message)) {
      event.preventDefault()
      event.stopImmediatePropagation()
    }
  }
}
