import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["card"];

  select(event) {
    const clickedCard = event.currentTarget;

    // Add loading state to clicked card
    clickedCard.classList.add("difficulty-card--loading");

    // Fade out other cards
    this.cardTargets.forEach((card) => {
      if (card !== clickedCard) {
        card.classList.add("difficulty-card--faded");
      }
    });

    // Create and append the loading overlay
    const overlay = document.createElement("div");
    overlay.className = "difficulty-card__loading-overlay";
    overlay.innerHTML = `
      <div class="loading-drops">
        <div class="loading-drops__drop"></div>
        <div class="loading-drops__drop"></div>
        <div class="loading-drops__drop"></div>
      </div>
      <span class="loading-drops__text">Preparing your game...</span>
    `;
    clickedCard.appendChild(overlay);
  }
}
