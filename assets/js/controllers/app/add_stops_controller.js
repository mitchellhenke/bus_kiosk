import { Controller } from "stimulus"
import Storage from "../../storage"

export default class extends Controller {
  static targets = [ "name" ]

  // The controller defaults to display:none, but if this set of
  // stop ids have not been saved, we add the not-saved class,
  // which will display:inherit (and show the input and button).
  connect() {
    const stopIds = this.data.get("stop-ids").split(',');
    if(!Storage.savedStopsExist(stopIds)) {
      this.element.classList.add("not-saved");
    }
  }

  // Data attributes have to be strings, and we have a list
  // so they are comma separated lists like "64,1711" and
  // "WISCONSIN AND WATER,WATER AND CHICAGO".
  // stop-names gets split and joined back to have a space after comma.
  // This will break if a stop name has a comma in it (none do at the moment).
  // If the text input is not empty, the saved stop(s) will use that, else
  // it will use the re-joined stop names.
  // Right now we save the name and the stopIds, but it's an object so we
  // can store other things too.
  save() {
    const stopIds = this.data.get("stop-ids").split(',');
    const stopNames = this.data.get("stop-names").split(',').join(', ');
    const nameInput = this.nameTarget.value;

    this.element.classList.remove("not-saved");
    if(nameInput === "") {
      Storage.addSavedStops(stopIds, stopNames);
    } else {
      Storage.addSavedStops(stopIds, nameInput);
    }
  }
}
