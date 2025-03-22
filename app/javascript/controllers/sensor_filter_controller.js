import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["startDate", "endDate"];
  static values = { sensorId: String };

  update() {
    const startDate = this.startDateTarget.value;
    const endDate = this.endDateTarget.value;
    const sensorId = this.sensorIdValue;

    // Build query parameters if dates are provided.
    const params = new URLSearchParams();
    if (startDate) params.append("start_date", startDate);
    if (endDate) params.append("end_date", endDate);

    fetch(`/sensors/${sensorId}/time_series?${params.toString()}`, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
      .then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html));
  }
}
