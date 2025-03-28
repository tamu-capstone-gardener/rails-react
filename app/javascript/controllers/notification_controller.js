import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Listen to turbo submit end events on the whole controller element.
    // You can also attach this listener directly on the form if preferred.
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this));
  }

  handleSubmitEnd(event) {
    // Check if submission was successful
    if (event.detail.success) {
      // If so, close the modal.
      this.closeModal();
    }
  }

  openModal() {
    const modal = document.getElementById("notification-modal")
    if (modal) {
      modal.classList.remove("hidden")
    }
  }

  closeModal() {
    const modal = document.getElementById("notification-modal")
    if (modal) {
      modal.classList.add("hidden")
    }
  }
}
