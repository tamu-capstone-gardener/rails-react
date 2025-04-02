import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  trigger(event) {
    const controlSignalId = event.currentTarget.dataset.id
    const plantModuleId = event.currentTarget.dataset.plantModuleId
    // Read the toggle data attribute from the button. It will be "true" or "false" (as strings).
    const toggle = event.currentTarget.dataset.toggle === "true"
    if (!controlSignalId || !plantModuleId) return

    fetch(`/plant_modules/${plantModuleId}/control_signals/${controlSignalId}/trigger`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
        "Content-Type": "application/json"
      },
      // Include toggle in the payload alongside the source.
      body: JSON.stringify({ source: "manual", toggle: toggle })
    })
      .then(res => {
        if (res.ok) {
          event.currentTarget.classList.add("bg-green-500")
          setTimeout(() => {
            event.currentTarget.classList.remove("bg-green-500")
          }, 1000)
        } else {
          console.error("Trigger failed")
        }
      })
      .catch(err => console.error("Error:", err))
  }
}
