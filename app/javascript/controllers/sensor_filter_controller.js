// sensor_filter_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["startDate"];
  static values = { sensorId: String };

  update() {
    const startDate = this.startDateTarget.value;
    const sensorId = this.sensorIdValue;
    const params = new URLSearchParams();
    if (startDate) params.append("start_date", startDate);

    fetch(`/sensors/${sensorId}/time_series?${params.toString()}`, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
      .then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html));
  }

  changeRange(event) {
  const range = event.currentTarget.dataset.range;
  const sensorId = this.sensorIdValue;
  const url = `/sensors/${sensorId}/time_series_chart?range=${range}`;
  fetch(url, {
    headers: { Accept: "text/vnd.turbo-stream.html" }
  })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html);
      // Give Turbo a moment to update the DOM, then trigger Chartkick initialization.
      requestAnimationFrame(() => {
        // Optionally, if your dark mode code is needed:
        const chartEl = this.element.querySelector(`#chart-${sensorId}`);
        if (chartEl) {
          chartEl.dispatchEvent(new CustomEvent("dark-mode:refresh", { bubbles: true }));
        }
      });
    });
}

  
}
