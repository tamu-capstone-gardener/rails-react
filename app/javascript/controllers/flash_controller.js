import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = 3000; // Flash message disappears after 3 seconds
    this.hideAfterDelay();
  }

  hideAfterDelay() {
    setTimeout(() => {
      this.dismiss();
    }, this.timeout);
  }

  dismiss() {
    this.element.classList.add("opacity-0", "transition-opacity", "duration-500");

    // Ensure the element is removed after transition ends
    this.element.addEventListener("transitionend", () => {
      this.element.classList.add("hidden");
    }, { once: true }); // Ensures it only fires once
  }
}
