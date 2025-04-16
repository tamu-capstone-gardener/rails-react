// app/javascript/controllers/tabs_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = {
    default: String
  }

  connect() {
    const saved = localStorage.getItem(this.storageKey())
    const activeTab = saved || this.defaultValue

    this.showTab(activeTab)
    this.switchTo(activeTab)
  }
  switch(event) {
    const tab = event.currentTarget.dataset.tab
    this.showTab(tab)
    localStorage.setItem(this.storageKey(), tab)
    this.switchTo(event.currentTarget.dataset.tab)
  }

  switchTo(targetTab) {
    this.tabTargets.forEach(el => {
      el.classList.toggle("btn-primary", el.dataset.tab === targetTab)
      el.classList.toggle("text-white", el.dataset.tab === targetTab)
    })

    this.panelTargets.forEach(el => {
      el.classList.toggle("hidden", el.dataset.tabPanel !== targetTab)
    })
  }

  showTab(selected) {
    this.tabTargets.forEach((el) => {
      el.classList.toggle("theme-tab-active", el.dataset.tab === selected)
    })

    this.panelTargets.forEach((el) => {
      el.classList.toggle("hidden", el.dataset.tabPanel !== selected)
    })
  }

  storageKey() {
    return `tab-${this.element.id || "default"}`
  }
}
