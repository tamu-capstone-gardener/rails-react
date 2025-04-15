import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggle() {
    document.documentElement.classList.toggle("dark");
    localStorage.theme = document.documentElement.classList.contains("dark") ? "dark" : "light";
    window.dispatchEvent(new Event("themeChanged"));

    const dot = this.element.querySelector(".dot");
    if (dot) {
      dot.classList.toggle("translate-x-1");
      dot.classList.toggle("translate-x-5");
    }
  }

  connect() {
    const prefersDark = localStorage.theme === "dark" ||
      (!("theme" in localStorage) && window.matchMedia("(prefers-color-scheme: dark)").matches);
    if (prefersDark) {
      document.documentElement.classList.add("dark");
    }

    const dot = this.element.querySelector(".dot");
    if (dot) {
      dot.classList.remove("translate-x-1", "translate-x-5");
      dot.classList.add(prefersDark ? "translate-x-5" : "translate-x-1");
    }
  }
}
