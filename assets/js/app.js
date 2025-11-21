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
    // Only re-init if data changed significantly to avoid jitter
    if (this.el.dataset.route !== this.lastRoute) {
      this.initMap();
    }
  },
  destroyed() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  },
  initMap() {
    if (!this.el.dataset.route) return;
    this.lastRoute = this.el.dataset.route;
    
    // 1. Parse Data
    let routePoints = [];
    try {
      const raw = JSON.parse(this.el.dataset.route);
      if (Array.isArray(raw)) {
        routePoints = raw;
      } else if (raw.coordinates) {
        routePoints = raw.coordinates;
      }
    } catch(e) { console.error("GPX Parse Error", e); return; }

    if (!routePoints || routePoints.length === 0) return;

    // 2. Setup Map Layers
    const osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap'
    });

    const satellite = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
      attribution: 'Tiles &copy; Esri'
    });

    const terrain = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
      attribution: 'Map data: &copy; OpenStreetMap contributors, SRTM | Map style: &copy; OpenTopoMap (CC-BY-SA)'
    });

    // Check if Expanded (Lightbox)
    const isExpanded = this.el.dataset.expanded === "true";

    // 3. Initialize Map
    if (this.map) this.map.remove();
    
    this.map = L.map(this.el.id, {
      center: [routePoints[0][0], routePoints[0][1]],
      zoom: 13,
      layers: [isExpanded ? terrain : osm], // Default to Terrain in Lightbox
      scrollWheelZoom: isExpanded,
      zoomControl: false // We add it manually below
    });

    if(isExpanded) {
      L.control.layers({
        "Standard": osm,
        "Terrain": terrain,
        "Satellite": satellite
      }).addTo(this.map);
      
      L.control.zoom({ position: 'topright' }).addTo(this.map);
      L.control.scale().addTo(this.map);
    }

    // 4. Draw Route
    // Leaflet expects [lat, lon], but our data might be [lat, lon, ele]
    // slice(0,2) ensures we only give Leaflet lat/lon
    const latLngs = routePoints.map(p => [p[0], p[1]]);
    
    const polyline = L.polyline(latLngs, {
      color: '#2563eb', // Blue-600
      weight: isExpanded ? 4 : 3,
      opacity: 0.9,
      lineJoin: 'round'
    }).addTo(this.map);

    this.map.fitBounds(polyline.getBounds(), {
      padding: isExpanded ? [50, 50] : [20, 20]
    });

    // 5. Add Markers (Start/Finish) if Expanded
    if (isExpanded) {
      // Start Icon (Green Dot)
      const startIcon = L.divIcon({
        className: 'bg-green-500 border-2 border-white rounded-full shadow-md',
        iconSize: [12, 12]
      });
      L.marker(latLngs[0], {icon: startIcon}).addTo(this.map).bindPopup("Start");

      // Finish Icon (Red Checkered)
      const finishIcon = L.divIcon({
        className: 'bg-red-600 border-2 border-white rounded-full shadow-md',
        iconSize: [12, 12]
      });
      L.marker(latLngs[latLngs.length - 1], {icon: finishIcon}).addTo(this.map).bindPopup("Finish");

      // 6. Initialize Chart if canvas exists
      const chartCanvas = document.getElementById('elevation-chart');
      if (chartCanvas && routePoints.length > 0) {
        this.initChart(chartCanvas, routePoints, latLngs);
      }
    }
  },

  initChart(canvas, routePoints, latLngs) {
    // Extract Elevation Data
    // We need to calculate distance for the X-axis to be accurate
    let distAcc = 0;
    const data = routePoints.map((p, i) => {
      if (i > 0) {
        const prev = routePoints[i-1];
        distAcc += this.distance(prev[0], prev[1], p[0], p[1]);
      }
      // FIX: SAFE ACCESS for 2D data arrays (p[2] might be undefined)
      return { x: distAcc, y: p[2] || 0, latLng: latLngs[i] }; 
    });

    const ctx = canvas.getContext('2d');
    
    // Position marker on map
    const positionMarker = L.circleMarker([0,0], {
      radius: 6,
      fillColor: "#2563eb",
      color: "#fff",
      weight: 2,
      fillOpacity: 1
    }).addTo(this.map);
    
    // Hide initially
    positionMarker.setLatLng([0,0]);
    positionMarker.setStyle({opacity: 0, fillOpacity: 0});

    if (this.chart) this.chart.destroy();

    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [{
          label: 'Elevation',
          data: data,
          borderColor: '#2563eb',
          backgroundColor: 'rgba(37, 99, 235, 0.1)',
          borderWidth: 2,
          pointRadius: 0, // Hide points by default
          pointHoverRadius: 4,
          fill: true,
          tension: 0.1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            displayColors: false,
            callbacks: {
              label: (context) => `${Math.round(context.raw.y)}m`,
              title: (context) => `${(context[0].raw.x).toFixed(1)}km`
            }
          }
        },
        scales: {
          x: {
            type: 'linear',
            title: { display: true, text: 'Distance (km)' },
            grid: { display: false }
          },
          y: {
            title: { display: true, text: 'Elevation (m)' },
            grid: { color: '#f1f5f9' }
          }
        },
        onHover: (e, elements) => {
          if (elements && elements.length > 0) {
            const index = elements[0].index;
            const point = data[index];
            
            // Move map marker
            positionMarker.setLatLng(point.latLng);
            positionMarker.setStyle({opacity: 1, fillOpacity: 1});
          } else {
            positionMarker.setStyle({opacity: 0, fillOpacity: 0});
          }
        }
      }
    });
  },

  // Helper: Haversine distance in km
  distance(lat1, lon1, lat2, lon2) {
    const R = 6371; 
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
    return R * c; 
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

