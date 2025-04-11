import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modeInput", "modeTabs", "automaticFields", "scheduledFields",
    "lengthSelect", "customLengthInput",
    "thresholdSelect", "customThresholdInput", "sensorSelect"
  ]

  connect() {
    requestAnimationFrame(() => {
      this.selectModeFromValue()
      this.toggleCustomLengthInput()
      this.updateThresholdFields()
      this.updateSensorUnit()
    })
  }

  updateThresholdFields() {
  const raw = this.element.dataset.controlSignalFormDefaultThresholdValue;
  const threshold = parseFloat(raw);
  const presetValues = ["10", "25", "50", "100", "500", "1000", "2500", "10000"];

  if (presetValues.includes(threshold.toString())) {
    // Set the select value
    this.thresholdSelectTarget.value = threshold;
    // Instead of reassigning the name, keep the original "control_signal[threshold_preset]"
    // Hide the custom input and ensure it doesn't submit a value
    this.customThresholdInputTarget.classList.add("hidden");
    this.customThresholdInputTarget.removeAttribute("name");
    this.customThresholdInputTarget.value = "";
  } else {
    this.thresholdSelectTarget.value = "custom";
    // For custom, you might want to ensure that only the custom field submits the value
    this.thresholdSelectTarget.removeAttribute("name");
    this.customThresholdInputTarget.classList.remove("hidden");
    // Optionally, you can explicitly set the name if needed
    // this.customThresholdInputTarget.setAttribute("name", "control_signal[threshold_custom]");
    this.customThresholdInputTarget.value = raw || "";
  }
}


  toggleCustomThresholdInput() {
    const isCustom = this.thresholdSelectTarget.value === "custom"
    this.customThresholdInputTarget.classList.toggle("hidden", !isCustom)
  }
  

  toggleCustomLengthInput() {
    const isCustom = this.lengthSelectTarget.value === "custom"

    if (isCustom) {
      this.lengthSelectTarget.removeAttribute("name")
      this.customLengthInputTarget.name = "control_signal[length_ms]"
      this.customLengthInputTarget.classList.remove("hidden")
    } else {
      this.lengthSelectTarget.name = "control_signal[length_ms]"
      this.customLengthInputTarget.removeAttribute("name")
      this.customLengthInputTarget.value = ""
      this.customLengthInputTarget.classList.add("hidden")
    }
  }

  updateSensorUnit() {
    const selected = this.sensorSelectTarget.selectedOptions[0]
    const unit = selected?.dataset.unit || ""
    const unitSpan = this.element.querySelector("#sensor-unit")
    if (unitSpan) unitSpan.textContent = unit
  }

  selectMode(event) {
    this.modeInputTarget.value = event.currentTarget.dataset.mode
    this.selectModeFromValue()
  }

  selectModeFromValue() {
    const mode = this.modeInputTarget.value
    this.modeTabsTarget.querySelectorAll(".mode-tab").forEach(tab => {
      tab.classList.toggle("bg-blue-500", tab.dataset.mode === mode)
      tab.classList.toggle("text-white", tab.dataset.mode === mode)
    })

    if (this.hasAutomaticFieldsTarget) {
      this.automaticFieldsTarget.classList.toggle("hidden", mode !== "automatic")
    }

    if (this.hasScheduledFieldsTarget) {
      this.scheduledFieldsTarget.classList.toggle("hidden", mode !== "scheduled")
    }
  }
}
