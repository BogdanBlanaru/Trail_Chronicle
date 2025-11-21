// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}

Hooks.RaceMap = {
  mounted() {
    this.initMap();
  },
  updated() {
    this.initMap();
  },
  destroyed() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  },
  initMap() {
    if (!this.el.dataset.route) return;
    
    // FIX: Robust parsing to handle both formats
    let routePoints = [];
    try {
      const raw = JSON.parse(this.el.dataset.route);
      // Handle: data-route="[[45,25],...]" OR data-route='{"coordinates":[[45,25],...]}'
      if (Array.isArray(raw)) {
        routePoints = raw;
      } else if (raw.coordinates) {
        routePoints = raw.coordinates;
      }
    } catch(e) { console.error("GPX Parse Error", e); return; }

    if (routePoints && routePoints.length > 0) {
      if (this.map) {
         this.map.off();
         this.map.remove();
      }

      // Check if this is the "Expanded" lightbox map
      const isExpanded = this.el.dataset.expanded === "true";

      // Initialize Map
      this.map = L.map(this.el.id, {
        scrollWheelZoom: isExpanded, // Enable scroll zoom only in lightbox
        zoomControl: true
      }).setView(routePoints[0], 13);

      // Add Tiles
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors'
      }).addTo(this.map);

      // Add Route Line
      const polyline = L.polyline(routePoints, {
        color: '#2563eb', 
        weight: isExpanded ? 5 : 4, 
        opacity: 0.8
      }).addTo(this.map);
      
      // Fit Bounds
      this.map.fitBounds(polyline.getBounds(), {
        padding: isExpanded ? [50, 50] : [20, 20]
      });

      // Extra Features for Lightbox
      if (isExpanded) {
        L.control.scale().addTo(this.map);
        // Force redraw to fix grey tiles
        setTimeout(() => { this.map.invalidateSize(); }, 200);
      }
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

