import { Controller } from "@hotwired/stimulus";
import Chart from "chart.js/auto";

export default class extends Controller {
  static targets = ["chart"];
  static values = { data: Array, labels: Array, title: String, unit: String, darkMode: Boolean };

  connect() {
    console.log(`Rendering chart for ${this.titleValue}`);

    if (!this.hasChartTarget) {
      console.error("Chart target missing");
      return;
    }

    const ctx = this.chartTarget.getContext("2d");
    new Chart(ctx, {
      type: "line",
      data: {
        labels: this.labelsValue,
        datasets: [{
          label: this.titleValue,
          data: this.dataValue,
          borderColor: this.darkModeValue ? "rgb(255, 99, 132)" : "rgb(54, 162, 235)",
          backgroundColor: this.darkModeValue ? "rgba(255, 99, 132, 0.2)" : "rgba(54, 162, 235, 0.2)",
          borderWidth: 2,
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { labels: { color: this.darkModeValue ? "#ffffff" : "#000000" } },
          tooltip: { bodyColor: this.darkModeValue ? "#ffffff" : "#000000" }
        },
        scales: {
          x: {
            title: { display: true, text: "Timestamp", color: this.darkModeValue ? "#ffffff" : "#000000" },
            ticks: { color: this.darkModeValue ? "#ffffff" : "#000000" }
          },
          y: {
            title: { display: true, text: this.unitValue, color: this.darkModeValue ? "#ffffff" : "#000000" },
            ticks: { color: this.darkModeValue ? "#ffffff" : "#000000" }
          }
        }
      }
    });
  }
}
