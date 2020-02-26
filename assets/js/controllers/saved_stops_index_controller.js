import { Controller } from "stimulus"
import Storage from "../storage"

// The controller fetches all saved stops and displays the link
// to the "/live" page and a button to remove it.
// If there are no saved stops, they get a message telling them that.
export default class extends Controller {
  static targets = [ "stopsTemplate", "noStopsTemplate" ];
  connect() {
    const stops = Storage.getSavedStops();

    if(Object.keys(stops).length > 0) {
      this.renderStops(stops);
    } else {
      this.renderNoStops();
    }
  }

  // This makes use of the HTML <template> tag, and appends a child to the controller div
  // for each of the saved stops. The button gets a data-key attribute set with the value
  // of the key from the stored stops "database". #remove uses this id in the click callback
  // to delete it from the "database".
  renderStops(stops) {
    const template = this.stopsTemplateTarget;
    for (let [key, stop] of Object.entries(stops)) {
      const clone = template.content.cloneNode(true);
      const anchor = clone.querySelector("a");
      const strong = clone.querySelector("strong");
      const button = clone.querySelector("button");

      strong.textContent = stop.name;
      anchor.href = `/live?stop_ids=${key}`;
      button.setAttribute(`data-key`, `${key}`)
      button.setAttribute('data-action', `click->${this.identifier}#remove`)
      this.element.appendChild(clone);
    }
  }

  renderNoStops() {
    const template = this.noStopsTemplateTarget;
    const clone = template.content.cloneNode(true);
    this.element.appendChild(clone);
  }

  // Deletes from saved stops and removes parent element
  // to remove the row from the page.
  remove(el) {
    const key = el.target.getAttribute("data-key");
    const stops = Storage.removeSavedStops(key);
    el.target.parentNode.remove();
  }
}
