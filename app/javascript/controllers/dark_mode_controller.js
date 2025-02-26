// app/javascript/controllers/dark_mode_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Check if a user preference is already stored
    if ("theme" in localStorage) {
      if (localStorage.theme === "dark") {
        document.documentElement.classList.add("dark")
      } else {
        document.documentElement.classList.remove("dark")
      }
    } else {
      // If there's no stored preference, use the system preference
      if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
        document.documentElement.classList.add("dark")
      } else {
        document.documentElement.classList.remove("dark")
      }
    }
  }

  toggle() {
    // Toggle the .dark class on <html>:
    document.documentElement.classList.toggle("dark")

    // Save user’s preference in localStorage
    if (document.documentElement.classList.contains("dark")) {
      localStorage.theme = "dark"
    } else {
      localStorage.theme = "light"
    }
  }
}
