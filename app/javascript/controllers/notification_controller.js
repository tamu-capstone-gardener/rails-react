import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  handleSubmitEnd(event) {
    if (event.detail.success) {
      this.closeModal()
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

  closeOnBackgroundClick() {
    this.closeModal()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
