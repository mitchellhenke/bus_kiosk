// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"
import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import NearbyStopsController from "./controllers/nearby_stops_controller"
const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

const path = window.location.pathname
const isKiosk = path.startsWith("/live");
const isHome = (path === "/" || path === "");
const isNearby = path.startsWith("/nearby_stops");

if(isKiosk || isHome || isNearby) {
  let Hooks = {};
  if(isNearby) {
    Hooks.nearbyStops = NearbyStopsController.hooks();
  }
  let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
  let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}});
  liveSocket.connect()
}

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
