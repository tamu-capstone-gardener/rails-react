// app/javascript/controllers/plant_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  openModal(event) {
    const plantId = event.currentTarget.dataset.plantId;
    const modal = document.getElementById("plant-info-modal");
    const frame = document.getElementById("plant-info-content");
  
    frame.src = `/plants/${plantId}/info`;
    modal.classList.remove("hidden");
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
