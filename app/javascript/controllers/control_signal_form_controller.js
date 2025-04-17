// app/javascript/controllers/control_signal_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modeInput", "modeTabs",
    "automaticFields", "scheduledFields",
    "lengthSelect", "customLengthInput",
    "sensorSelect"
  ]

  connect() {
    requestAnimationFrame(() => {
      this.selectModeFromValue()
      this.toggleCustomLengthInput()
      this.updateSensorUnit()
    })
  }

  toggleCustomLengthInput() {
    const isCustom = this.lengthSelectTarget?.value === "custom"

    if (isCustom) {
      this.lengthSelectTarget.removeAttribute("name")
      this.customLengthInputTarget.name = "control_signal[length]"
      this.customLengthInputTarget.classList.remove("hidden")
    } else {
      this.lengthSelectTarget.name = "control_signal[length]"
      this.customLengthInputTarget.removeAttribute("name")
      this.customLengthInputTarget.value = ""
      this.customLengthInputTarget.classList.add("hidden")
    }
  }

  updateSensorUnit() {
    const selected = this.sensorSelectTarget?.selectedOptions[0]
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
      const isActive = tab.dataset.mode === mode
      tab.classList.toggle("bg-blue-500", isActive)
      tab.classList.toggle("text-white", isActive)
    })

    if (this.hasAutomaticFieldsTarget)
      this.automaticFieldsTarget.classList.toggle("hidden", mode !== "automatic")

    if (this.hasScheduledFieldsTarget)
      this.scheduledFieldsTarget.classList.toggle("hidden", mode !== "scheduled")
  }
}
