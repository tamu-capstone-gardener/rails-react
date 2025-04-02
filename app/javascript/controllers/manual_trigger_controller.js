import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  trigger(event) {
    const controlSignalId = event.currentTarget.dataset.id
    const plantModuleId = event.currentTarget.dataset.plantModuleId
    if (!controlSignalId || !plantModuleId) return

    fetch(`/plant_modules/${plantModuleId}/control_signals/${controlSignalId}/trigger`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name=csrf-token]").content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ source: "manual" })
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
