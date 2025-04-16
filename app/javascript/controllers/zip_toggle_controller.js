import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["zipField"]

  connect() {
    this.toggleZipField();
    this.syncToFilters(); // initial sync
  }

  toggleZipField() {
    const selected = this.element.querySelector('input[name="plant_module[location_type]"]:checked');
    if (!selected) return;

    const showZip = selected.value === "outdoor";
    if (this.hasZipFieldTarget) {
      this.zipFieldTarget.style.display = showZip ? "block" : "none";
    }

    this.syncToFilters();
  }

  syncToFilters() {
    const locationRadio = this.element.querySelector('input[name="plant_module[location_type]"]:checked');
    const zipInput = this.element.querySelector('input[name="plant_module[zip_code]"]');

    const locationValue = locationRadio?.value || "indoor";
    const zipValue = zipInput?.value || "";

    const locationFilter = document.querySelector('input[name="location_type"]');
    const zipFilter = document.querySelector('input[name="zip_code"]');

    if (locationFilter) locationFilter.value = locationValue;
    if (zipFilter) zipFilter.value = locationValue === "outdoor" ? zipValue : "";
  }
}
