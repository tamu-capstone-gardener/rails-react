import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  openModal(event) {
    const modal = document.getElementById("plant-info-modal")
    const content = document.getElementById("plant-info-content")
    const plant = JSON.parse(event.currentTarget.dataset.plant)

    const html = Object.entries(plant)
      .filter(([_, val]) => val && val !== "[]")
      .map(([key, val]) => {
        const label = key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
        return `<p><strong>${label}:</strong> ${val}</p>`
      })
      .join("")

    content.innerHTML = html
    modal.classList.remove("hidden")
  }

  closeModal() {
    document.getElementById("plant-info-modal").classList.add("hidden")
  }

  closeOnBackgroundClick() {
    this.closeModal()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
