import { Controller } from "stimulus"

export default class NearbyStopsController extends Controller {
  connect() {
  }

  locate() {
    const data = this.data;
    if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
      DeviceOrientationEvent.requestPermission()
        .then(permissionState => {
          if (permissionState === 'granted') {
            window.addEventListener('deviceorientation', function(e) {
              const newHeading = e.webkitCompassHeading;
              const heading = data.get("heading")
              const isValid = e.webkitCompassAccuracy > 0;
              if(isValid && (heading === null || (Math.abs(parseFloat(heading) - newHeading) > 10))) {
                const heading = data.set("heading", newHeading);
                const loc = { 'heading': newHeading };
                window.hook.pushEvent('location', loc);
              }
            }, false);
          }
        })
        .catch(console.error);
    } else {
      // handle regular non iOS 13+ devices
      console.error("HELLO")
    }

  }

  static hooks() {
    return {
      mounted() {
        this.getLocation(this);
      },
      getLocation(hook) {
        window.hook = hook
        if ('geolocation' in navigator) {
          navigator.geolocation.getCurrentPosition(function(position) {
            const loc = { 'latitude': position.coords.latitude, 'longitude': position.coords.longitude, 'heading': position.coords.heading };
            hook.pushEvent('location', loc)
          }, function(error) {
            console.error(error)
            hook.pushEvent('location', {'error': error})
          });
        } else {
          console.error("WTF")
          hook.pushEvent('location', {'error': 'no_permission'})
        }
      }
    }
  }
}
