import { Controller } from "stimulus"

export default class NearbyStopsController extends Controller {
  connect() {
  }

  static hooks() {
    return {
      mounted() {
        this.getLocation(this);
      },
      getLocation(hook) {
        if ("geolocation" in navigator) {
          navigator.geolocation.getCurrentPosition(function(position) {
            const loc = {'latitude': position.coords.latitude, 'longitude': position.coords.longitude};
            hook.pushEvent("location", loc)
          }, function(error) {
            hook.pushEvent("location", ["error", error])
          });
        } else {
          hook.pushEvent("location", "no_permission")
        }
      }
    }
  }
}
