import { Controller } from "@hotwired/stimulus";

// Toast notification controller
// Manages a stack of toast notifications that appear in the corner
// Supports auto-dismiss and manual close
export default class extends Controller {
  static targets = ["container"];
  static values = {
    position: { type: String, default: "top-right" },
    autoDismiss: { type: Number, default: 5000 }, // 0 to disable
  };

  connect() {
    // Process any toasts that were rendered on page load
    this.element
      .querySelectorAll(".toast:not(.toast--visible)")
      .forEach((toast) => {
        this.showToast(toast);
      });

    // Watch for new toasts added via Turbo Streams
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (
            node.nodeType === Node.ELEMENT_NODE &&
            node.classList.contains("toast")
          ) {
            this.showToast(node);
          }
        });
      });
    });

    this.observer.observe(this.element, { childList: true });
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  // Show a toast with animation
  showToast(toast) {
    // Small delay to allow CSS transition
    requestAnimationFrame(() => {
      toast.classList.add("toast--visible");
    });

    // Set up auto-dismiss if enabled and toast doesn't have data-persist
    const autoDismiss = toast.dataset.autoDismiss
      ? parseInt(toast.dataset.autoDismiss, 10)
      : this.autoDismissValue;

    if (autoDismiss > 0 && !toast.dataset.persist) {
      setTimeout(() => {
        this.dismissToast(toast);
      }, autoDismiss);
    }
  }

  // Dismiss a toast (called from close button or auto-dismiss)
  dismiss(event) {
    const toast = event.currentTarget.closest(".toast");
    if (toast) {
      this.dismissToast(toast);
    }
  }

  dismissToast(toast) {
    toast.classList.remove("toast--visible");
    toast.classList.add("toast--hiding");

    // Remove from DOM after animation
    toast.addEventListener(
      "transitionend",
      () => {
        toast.remove();
      },
      { once: true },
    );

    // Fallback removal if transition doesn't fire
    setTimeout(() => {
      if (toast.parentNode) {
        toast.remove();
      }
    }, 500);
  }

  // Add a new toast programmatically (can be called from other controllers)
  add(html) {
    const template = document.createElement("template");
    template.innerHTML = html.trim();
    const toast = template.content.firstChild;
    this.containerTarget.appendChild(toast);
    this.showToast(toast);
  }
}
