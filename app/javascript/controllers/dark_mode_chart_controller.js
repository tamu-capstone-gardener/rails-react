// app/javascript/controllers/dark_mode_chart_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.updateTheme();
    // Listen for theme changes (triggered by the dark mode toggle)
    window.addEventListener("themeChanged", this.updateTheme.bind(this));
  }

  updateTheme() {
    const isDark = document.documentElement.classList.contains("dark");
    // Define color values based on theme
    const appTextColor = isDark ? "#ffffff" : "#1f2937";
    const appGridColor = isDark ? "rgba(255, 255, 255, 0.2)" : "rgba(0, 0, 0, 0.1)";
    
    // Update the CSS variables used in the chart options (e.g., in _chart.html.erb)
    document.documentElement.style.setProperty("--app-text", appTextColor);
    document.documentElement.style.setProperty("--app-grid-color", appGridColor);

    // Iterate over each Chartkick chart (using Object.values since Chartkick.charts is an object)
    if (window.Chartkick && Chartkick.charts) {
      Object.values(Chartkick.charts).forEach(chart => {
        if (chart.chart && chart.chart.options) {
          // Update legend label colors
          if (chart.chart.options.plugins &&
              chart.chart.options.plugins.legend &&
              chart.chart.options.plugins.legend.labels) {
            chart.chart.options.plugins.legend.labels.color = appTextColor;
          }
          // Update scales for x and y axes, including title colors
          if (chart.chart.options.scales) {
            // Update x axis
            if (chart.chart.options.scales.x) {
              if (chart.chart.options.scales.x.ticks) {
                chart.chart.options.scales.x.ticks.color = appTextColor;
              }
              if (chart.chart.options.scales.x.grid) {
                chart.chart.options.scales.x.grid.color = appGridColor;
              }
              if (chart.chart.options.scales.x.title) {
                chart.chart.options.scales.x.title.color = appTextColor;
              }
            }
            // Update y axis
            if (chart.chart.options.scales.y) {
              if (chart.chart.options.scales.y.ticks) {
                chart.chart.options.scales.y.ticks.color = appTextColor;
              }
              if (chart.chart.options.scales.y.grid) {
                chart.chart.options.scales.y.grid.color = appGridColor;
              }
              if (chart.chart.options.scales.y.title) {
                chart.chart.options.scales.y.title.color = appTextColor;
              }
            }
          }
          // Force the chart to update
          chart.chart.update();
        }
      });
    }
  }
}
