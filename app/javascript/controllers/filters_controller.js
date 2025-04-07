import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  applyFilters(event) {
    event.preventDefault();
    const maxHeight = document.querySelector('input[name="max_height"]').value;
    const maxWidth  = document.querySelector('input[name="max_width"]').value;
    const maintenance = document.querySelector('select[name="maintenance"]').value;
    const edibilityRating = document.querySelector('select[name="edibility_rating"]').value;

    const url = new URL(window.location.href);
    url.searchParams.set("max_height", maxHeight);
    url.searchParams.set("max_width", maxWidth);
    url.searchParams.set("maintenance", maintenance);
    url.searchParams.set("edibility_rating", edibilityRating);

    Turbo.visit(url.toString());
  }
}
