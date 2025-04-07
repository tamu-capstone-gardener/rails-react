import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  selectPlant(event) {
    event.preventDefault();
    const button = event.currentTarget;
    // Find the recommendation card being selected
    const recommendationCard = button.closest('[data-plant-card]');
    if (!recommendationCard) return;
    
    // Clone the entire recommendation card to mirror its markup
    const clonedCard = recommendationCard.cloneNode(true);
    
    // In the cloned card, remove the "Select" button and add a "Remove" button
    const actionContainer = clonedCard.querySelector('.flex.justify-end.space-x-2');
    if (actionContainer) {
      // Remove the select button (if present)
      const selectBtn = actionContainer.querySelector('[data-action*="selectPlant"]');
      if (selectBtn) {
        selectBtn.remove();
      }
      // If a remove button doesn't exist yet, create one and append it
      if (!actionContainer.querySelector('[data-action*="removePlant"]')) {
        const removeBtn = document.createElement('button');
        removeBtn.type = "button";
        removeBtn.className = "remove-plant-btn py-2 px-4 bg-red-500 text-white rounded-lg hover:bg-red-600 focus:outline-none";
        removeBtn.textContent = "Remove";
        removeBtn.setAttribute("data-action", "click->plant-module#removePlant");
        actionContainer.appendChild(removeBtn);
      }
    }
    
    // Ensure the cloned card includes the hidden input that will be used for validation.
    let hiddenInput = clonedCard.querySelector('input[name="plant_module[plant_ids][]"]');
    if (!hiddenInput) {
      hiddenInput = document.createElement('input');
      hiddenInput.type = "hidden";
      hiddenInput.name = "plant_module[plant_ids][]";
      hiddenInput.value = button.dataset.plantId;
      // Append the hidden input to the cloned card (it will be submitted as part of the form)
      clonedCard.appendChild(hiddenInput);
    }
    
    // Append the cloned card to the selected plants list container
    const selectedPlantsList = document.getElementById('selected-plants-list');
    if (selectedPlantsList) {
      selectedPlantsList.appendChild(clonedCard);
    }
    
    // Remove the original recommendation card from the recommendations list
    recommendationCard.remove();
  }
  
  removePlant(event) {
    event.preventDefault();
    const button = event.currentTarget;
    // Remove the card from the selected plants list
    const plantCard = button.closest('[data-plant-card]');
    if (plantCard) {
      plantCard.remove();
    }
  }
  
  validateForm(event) {
    // Look for all hidden inputs within the form that represent a selected plant
    const selectedPlants = document.querySelectorAll('input[name="plant_module[plant_ids][]"]');
    if (selectedPlants.length === 0) {
      event.preventDefault();
      alert("Please select at least one plant.");
    }
  }
  
  toggleInfo(event) {
    event.preventDefault();
    const button = event.currentTarget;
    // Find the parent plant card container
    const card = button.closest('[data-plant-card]');
    // Toggle the hidden info container within the card
    const infoContainer = card.querySelector('.plant-info');
    infoContainer.classList.toggle('hidden');
  }
}
