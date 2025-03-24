// app/javascript/controllers/dark_mode_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Use the saved preference if available.
    // If no preference is saved, default to the system's setting.
    if (localStorage.theme === "dark" || 
      (!("theme" in localStorage) && window.matchMedia("(prefers-color-scheme: dark)").matches)) {
    document.documentElement.classList.add("dark")
    window.dispatchEvent(new Event("themeChanged"));
  } else {
    document.documentElement.classList.remove("dark")
  }
  }

  toggle() {
    // Toggle the dark class on <html>
    document.documentElement.classList.toggle("dark")
    const isDark = document.documentElement.classList.contains("dark");

    // Save user’s preference in localStorage
    localStorage.theme = isDark ? "dark" : "light";

    // Dispatch custom event to update charts and other elements
    window.dispatchEvent(new Event("themeChanged"));
  }
}
