import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  showModal(event) {
    event.preventDefault();

    // Get location ID from the button's data attribute
    const locationId = event.params.locationId;

    // Find the pre-rendered modal template
    const template = document.getElementById(`buddy-modal-${locationId}`);

    if (!template) {
      console.error(`Modal template not found for location ${locationId}`);
      return;
    }

    // Clone the template content
    const modalContent = template.cloneNode(true);

    // Create modal wrapper
    const modal = document.createElement("div");
    modal.className = "modal";
    modal.innerHTML = modalContent.innerHTML;

    // Add to DOM
    document.body.appendChild(modal);

    // Add event listener to close on backdrop click
    modal.addEventListener("click", (e) => {
      if (e.target === modal) {
        this.closeModal(modal);
      }
    });

    // Add close button handler
    const closeBtn = modal.querySelector(".modal__close");
    if (closeBtn) {
      closeBtn.addEventListener("click", () => this.closeModal(modal));
    }
  }

  closeModal(modal) {
    modal.remove();
  }
}
