export default class Storage {
  static getSavedStops() {
    const savedStops = localStorage.getItem("savedStops");

    if(savedStops) {
      return JSON.parse(savedStops);
    } else {
      return {};
    }
  }

  static addSavedStops(stopIdsList, name) {
    const savedStops = this.getSavedStops();
    const key = this.stopIdsToSavedStopsKey(stopIdsList);
    const value = {
      'stop_ids': stopIdsList,
      'name': name
    };

    savedStops[key] = value;

    localStorage.setItem("savedStops", JSON.stringify(savedStops));
  }

  static removeSavedStops(key) {
    const savedStops = this.getSavedStops();
    delete savedStops[key];

    localStorage.setItem("savedStops", JSON.stringify(savedStops));
  }

  static savedStopsExist(stopIdsList) {
    const savedStops = this.getSavedStops();
    const key = this.stopIdsToSavedStopsKey(stopIdsList);
    if(savedStops[key]) {
      return true;
    } else {
      return false;
    }
  }

  static stopIdsToSavedStopsKey(stopIdsList) {
    return stopIdsList.join(',');
  }
}
