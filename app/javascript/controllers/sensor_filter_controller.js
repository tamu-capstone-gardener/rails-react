import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  update(event) {
    let days = event.target.value;
    
    // Send a Turbo request with params
    fetch(`/sensors/${this.element.dataset.sensorId}/time_series?days=${days}`, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
    .then(response => response.text())
    .then(html => Turbo.renderStreamMessage(html));
  }
}
