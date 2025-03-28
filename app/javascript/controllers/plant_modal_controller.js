// app/javascript/controllers/plant_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {

  }

  openModal(event) {
    const modal = document.getElementById("plant-info-modal")
    const content = document.getElementById("plant-info-content")

    // Get plant data from the button
    const plant = JSON.parse(event.currentTarget.dataset.plant)

    // Format plant data as HTML
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
}
