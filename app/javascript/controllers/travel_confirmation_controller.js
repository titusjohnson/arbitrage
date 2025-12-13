import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    from: String,
    to: String,
    cost: Number,
    costLabel: String,
  };

  confirm(event) {
    const costText =
      this.costValue === 0 ? "free" : `for ${this.costLabelValue}`;
    const message = `Travel from ${this.fromValue} to ${this.toValue} ${costText}?`;

    if (!window.confirm(message)) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }
}
