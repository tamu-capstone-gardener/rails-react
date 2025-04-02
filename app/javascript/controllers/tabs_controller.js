import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.switchTo("care") // default
  }

  switch(event) {
    const targetTab = event.currentTarget.dataset.tab
    this.switchTo(targetTab)
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
