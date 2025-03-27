import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "zipField" ]

  connect() {
    this.toggleZipField();
  }

  toggleZipField() {
    // Find the selected radio button value
    const locationType = this.element.querySelector('input[name="plant_module[location_type]"]:checked').value;
    this.zipFieldTarget.style.display = locationType === "outdoor" ? "block" : "none";
  }
}
