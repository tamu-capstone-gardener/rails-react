import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = {
    default: String
  }

  connect() {
    const defaultTab = this.hasDefaultValue ? this.defaultValue : this.tabTargets[0]?.dataset.tab
    if (defaultTab) this.switchTo(defaultTab)
  }

  switch(event) {
    this.switchTo(event.currentTarget.dataset.tab)
  }

  switchTo(targetTab) {
    this.tabTargets.forEach(el => {
      el.classList.toggle("bg-blue-500", el.dataset.tab === targetTab)
      el.classList.toggle("text-white", el.dataset.tab === targetTab)
    })

    this.panelTargets.forEach(el => {
      el.classList.toggle("hidden", el.dataset.tabPanel !== targetTab)
    })
  }
}
