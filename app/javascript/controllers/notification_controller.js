import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  openModal() {
    document.getElementById("notification-modal").classList.remove("hidden")
  }

  closeModal() {
    document.getElementById("notification-modal").classList.add("hidden")
  }

  closeOnBackgroundClick() {
    this.closeModal()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  handleSubmitEnd(event) {
    if (event.detail.success) {
      this.closeModal()
    }
  }
}
