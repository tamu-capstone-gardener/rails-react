import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "entry"]

  add() {
    const row = document.createElement("div")
    row.classList.add("flex", "items-center", "gap-2", "mb-2")
    row.innerHTML = `
      <select name="comparisons[]" class="border select p-1 rounded">
        <option value="<=">&le;</option>
        <option value="<">&lt;</option>
        <option value="=">=</option>
        <option value=">=">&ge;</option>
        <option value=">">&gt;</option>
      </select>
      <input type="text" name="values[]" class="border p-1 rounded w-1/3" placeholder="Threshold value" />
      <input type="text" name="messages[]" class="border p-1 rounded w-1/2" placeholder="Message" />
      <button type="button" data-action="click->thresholds#remove" class="text-red-500">&times;</button>
    `
    this.containerTarget.appendChild(row)
  }

  remove(event) {
    event.target.closest("div").remove()
  }
}
