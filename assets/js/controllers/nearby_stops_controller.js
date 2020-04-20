import { Controller } from "stimulus"

export default class NearbyStopsController extends Controller {
  connect() {
    if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
      this.element.classList.remove('hide');
    } else {
      this.locate();
    }
  }

  locate() {
    const data = this.data;
    if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
      DeviceOrientationEvent.requestPermission()
        .then(permissionState => {
          if (permissionState === 'granted') {
            this.element.classList.add('hide');
            window.addEventListener('deviceorientation', function(e) {
              const newHeading = e.webkitCompassHeading;
              const heading = data.get("heading")
              const isValid = e.webkitCompassAccuracy > 0;
              if(isValid) {
                const heading = data.set("heading", newHeading);
                const loc = { 'heading': newHeading };
                window.hook.pushEvent('location', loc);
              }
            }, false);
          }
        })
        .catch(console.error);
    } else {
      window.addEventListener('deviceorientation', function(e) {
        const alpha = e.alpha;
        const gamma = e.gamma;
        const beta = e.beta;

        // Convert degrees to radians
        const alphaRad = alpha * (Math.PI / 180);
        const betaRad = beta * (Math.PI / 180);
        const gammaRad = gamma * (Math.PI / 180);

        // Calculate equation components
        const cA = Math.cos(alphaRad);
        const sA = Math.sin(alphaRad);
        const cB = Math.cos(betaRad);
        const sB = Math.sin(betaRad);
        const cG = Math.cos(gammaRad);
        const sG = Math.sin(gammaRad);

        // Calculate A, B, C rotation components
        const rA = - cA * sG - sA * sB * cG;
        const rB = - sA * sG + cA * sB * cG;
        const rC = - cB * cG;

        // Calculate compass heading
        let compassHeading = Math.atan(rA / rB);

        // Convert from half unit circle to whole unit circle
        if(rB < 0) {
          compassHeading += Math.PI;
        }else if(rA < 0) {
          compassHeading += 2 * Math.PI;
        }

        // Convert radians to degrees
        newHeading *= 180 / Math.PI;

        const heading = data.get("heading")

        if(isValid) {
          const heading = data.set("heading", newHeading);
          const loc = { 'heading': newHeading };
          window.hook.pushEvent('location', loc);
        }
      }, false);
    }
  }

  static hooks() {
    return {
      mounted() {
        this.getLocation(this);
      },
      reconnected() {
        this.getLocation(this);
      },
      getLocation(hook) {
        window.hook = hook
        if ('geolocation' in navigator) {
          navigator.geolocation.watchPosition(function(newPosition) {
            const element = document.getElementById('nearby-stops-location')

            let oldPosition = element.dataset.position;
            let distance = undefined;
            let time = undefined;
            if(oldPosition) {
              oldPosition = JSON.parse(oldPosition);
              distance = (Math.abs(oldPosition.coords.latitude - newPosition.coords.latitude) * 78710) +
                (Math.abs(oldPosition.coords.longitude - newPosition.coords.longitude) * 78710);
              time = newPosition.timestamp - oldPosition.timestamp;
            }

            if(oldPosition === undefined || distance > 10 || time > 10000) {
              const loc = { 'latitude': newPosition.coords.latitude, 'longitude': newPosition.coords.longitude };
              const j = hook.pushEvent('location', loc);
              element.dataset.position = JSON.stringify({coords: {
                latitude: newPosition.coords.latitude,
                longitude: newPosition.coords.longitude
              }, timestamp: newPosition.timestamp});
            }
          }, function(error) {
            console.error(error);
            hook.pushEvent('location', {'error': error});
          }, {enableHighAccuracy: true});
        } else {
          console.error('no location permission');
          hook.pushEvent('location', {'error': 'no_permission'});
        }
      }
    }
  }
}
