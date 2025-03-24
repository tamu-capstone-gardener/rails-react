import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.updateTheme();
    window.addEventListener("themeChanged", this.updateTheme.bind(this));
  }

  updateTheme() {
    const isDark = document.documentElement.classList.contains("dark");
    const appTextColor = isDark ? "#ffffff" : "#1f2937";
    const appGridColor = isDark ? "rgba(255, 255, 255, 0.2)" : "rgba(0, 0, 0, 0.1)";
    
    document.documentElement.style.setProperty("--app-text-primary", appTextColor);
    document.documentElement.style.setProperty("--app-grid-color", appGridColor);

    if (window.Chartkick && Chartkick.charts) {
      Object.values(Chartkick.charts).forEach(chart => {
        if (chart.chart && chart.chart.options) {
          if (chart.chart.options.plugins?.legend?.labels) {
            chart.chart.options.plugins.legend.labels.color = appTextColor;
          }
          if (chart.chart.options.scales) {
            if (chart.chart.options.scales.x) {
              chart.chart.options.scales.x.ticks.color = appTextColor;
              chart.chart.options.scales.x.grid.color = appGridColor;
              if (chart.chart.options.scales.x.title) {
                chart.chart.options.scales.x.title.color = appTextColor;
              }
            }
            if (chart.chart.options.scales.y) {
              chart.chart.options.scales.y.ticks.color = appTextColor;
              chart.chart.options.scales.y.grid.color = appGridColor;
              if (chart.chart.options.scales.y.title) {
                chart.chart.options.scales.y.title.color = appTextColor;
              }
            }
          }
          chart.chart.update();
        }
      });
    }
  }
}
