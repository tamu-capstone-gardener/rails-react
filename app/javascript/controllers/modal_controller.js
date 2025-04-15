import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  open(event) {
    this.modalTargets.forEach(el => el.classList.add("hidden")) // Hide all others if needed
    event.stopPropagation()
    this.modalTarget.classList.remove("hidden")

    // Listen for outside clicks globally
    document.addEventListener("click", this.handleOutsideClick)
  }

  close(event) {
    this.modalTarget.classList.add("hidden")
    document.removeEventListener("click", this.handleOutsideClick)
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  handleOutsideClick = (event) => {
    if (!this.modalTarget.contains(event.target)) {
      this.close()
    }
  }
}
