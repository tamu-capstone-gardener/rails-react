// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  open(event) {
    this.modalTarget.classList.remove("hidden")
  }

  close(event) {
    this.modalTarget.classList.add("hidden")
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
