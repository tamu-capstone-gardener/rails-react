import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modeInput",
    "modeTabs",
    "automaticFields",
    "scheduledFields",
    "lengthSelect",
    "customLengthInput",
    "thresholdSelect",
    "customThresholdInput",
    "sensorSelect"
  ]

  connect() {
    requestAnimationFrame(() => {
      this.selectModeFromValue()
      this.toggleCustomLengthInput()
      this.toggleCustomThresholdInput()
      this.updateSensorUnit()
      // console.log("ControlSignalFormController connected ✅")
    })
  }

  selectMode(event) {
    const newMode = event.currentTarget.dataset.mode
    this.modeInputTarget.value = newMode
    this.selectModeFromValue()
  }

  selectModeFromValue() {
    const selectedMode = this.modeInputTarget.value
    // console.log("Selected mode:", selectedMode)

    // Visually highlight the selected tab
    this.modeTabsTarget.querySelectorAll(".mode-tab").forEach(tab => {
      if (tab.dataset.mode === selectedMode) {
        tab.classList.add("bg-blue-500", "text-white")
      } else {
        tab.classList.remove("bg-blue-500", "text-white")
      }
    })

    // Toggle relevant fieldsets
    if (this.hasAutomaticFieldsTarget) {
      this.automaticFieldsTarget.classList.toggle("hidden", selectedMode !== "automatic")
    }
    if (this.hasScheduledFieldsTarget) {
      this.scheduledFieldsTarget.classList.toggle("hidden", selectedMode !== "scheduled")
    }
  }

  updateSensorUnit() {
    const selectedOption = this.sensorSelectTarget.selectedOptions[0]
    const unit = selectedOption.dataset.unit
    const unitSpan = this.element.querySelector("#sensor-unit")
    if (unitSpan) unitSpan.textContent = unit || ""
  }    

  toggleCustomLengthInput() {
    if (this.hasCustomLengthInputTarget && this.hasLengthSelectTarget) {
      const isCustom = this.lengthSelectTarget.value === "custom";
      this.customLengthInputTarget.classList.toggle("hidden", !isCustom);
  
      if (isCustom) {
        // When custom is selected, remove the name from the select so it isn't submitted.
        this.lengthSelectTarget.removeAttribute("name");
        // And ensure the custom input is named so its value is submitted.
        this.customLengthInputTarget.setAttribute("name", "control_signal[length_ms]");
      } else {
        // When a preset is selected, remove the name from the custom input.
        this.customLengthInputTarget.removeAttribute("name");
        // And ensure the select carries the name.
        this.lengthSelectTarget.setAttribute("name", "control_signal[length_ms]");
        // Optionally clear the custom field.
        this.customLengthInputTarget.value = "";
      }
    }
  }
  
  

  toggleCustomThresholdInput() {
    if (this.hasCustomThresholdInputTarget && this.hasThresholdSelectTarget) {
      this.customThresholdInputTarget.classList.toggle("hidden", this.thresholdSelectTarget.value !== "custom")
    }
  }
}
  