import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "bars", "x", "backdrop"]
  static values = { state: Boolean }

  connect() {
    this.updateMenu()
  }

  toggle() {
    this.stateValue = !this.stateValue
    this.updateMenu()
  }

  close() {
    this.stateValue = false
    this.updateMenu()
  }

  updateMenu() {
    this.menuTarget.classList.toggle("-translate-x-full", !this.stateValue)
    this.menuTarget.classList.toggle("translate-x-0", this.stateValue)

    this.backdropTarget.classList.toggle("hidden", !this.stateValue)

    this.barsTarget.classList.toggle("hidden", this.stateValue)
    this.xTarget.classList.toggle("hidden", !this.stateValue)
  }
}
