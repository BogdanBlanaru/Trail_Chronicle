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

// IMPORT CHART.JS
import Chart from 'chart.js/auto';

let Hooks = {}

Hooks.RaceMap = {
  mounted() {
    this.initMap();
  },
  updated() {
    // Re-initialize if data changed, or just invalidate size if purely a layout update
    // We check if map exists to avoid re-creating it unnecessarily
    if (this.map) {
      // Small delay to allow modal transition to finish
      setTimeout(() => { this.map.invalidateSize(); }, 200);
      return; 
    }
    this.initMap();
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

    // Ensure container is clean
    if (this.map) this.map.remove();

    const isExpanded = this.el.dataset.expanded === "true";

    // 1. Define Layers
    const osm = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap'
    });

    const satellite = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
      attribution: 'Tiles &copy; Esri'
    });

    const terrain = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
      attribution: 'Map data: &copy; OpenStreetMap contributors, SRTM | Map style: &copy; OpenTopoMap (CC-BY-SA)'
    });

    // 2. Initialize Map
    // If data has [lat, lon, ele], use [0,1] for center
    this.map = L.map(this.el.id, {
      center: [routePoints[0][0], routePoints[0][1]],
      zoom: 13,
      layers: [isExpanded ? terrain : osm], // Default to Terrain in Lightbox
      scrollWheelZoom: isExpanded, 
      zoomControl: false, // We add it manually for better positioning
      dragging: true
    });

    if (isExpanded) {
      L.control.layers({
        "Standard": osm,
        "Terrain": terrain,
        "Satellite": satellite
      }).addTo(this.map);
      
      L.control.zoom({ position: 'topright' }).addTo(this.map);
      L.control.scale().addTo(this.map);
    }

    // 3. Draw Route
    // Leaflet needs [lat, lon]. Our data might be [lat, lon, ele].
    const latLngs = routePoints.map(p => [p[0], p[1]]);
    
    const polyline = L.polyline(latLngs, {
      color: '#2563eb', // Blue-600
      weight: isExpanded ? 4 : 3,
      opacity: 0.8,
      lineJoin: 'round'
    }).addTo(this.map);
    
    this.map.fitBounds(polyline.getBounds(), {
      padding: isExpanded ? [50, 50] : [20, 20]
    });

    // 4. Premium Features for Lightbox
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

      // 5. Initialize Chart
      // We look for the canvas element inside the parent container or by ID
      const chartCanvas = document.getElementById('elevation-chart');
      if (chartCanvas) {
        this.initChart(chartCanvas, routePoints, latLngs);
      }
    }
  },

  initChart(canvas, routePoints, latLngs) {
    // Calculate distances for X-axis
    let distAcc = 0;
    const data = routePoints.map((p, i) => {
      if (i > 0) {
        const prev = routePoints[i-1];
        distAcc += this.distance(prev[0], prev[1], p[0], p[1]);
      }
      // Check if elevation exists (index 2), otherwise default to 0
      const ele = p[2] !== undefined ? p[2] : 0;
      return { x: distAcc, y: ele, latLng: latLngs[i] }; 
    });

    // If chart exists, destroy it to prevent memory leaks/glitches
    if (this.chart) {
      this.chart.destroy();
    }

    const ctx = canvas.getContext('2d');

    // Add a marker for interaction
    const positionMarker = L.circleMarker([0,0], {
      radius: 8,
      fillColor: "#2563eb",
      color: "#fff",
      weight: 3,
      fillOpacity: 1,
      zIndexOffset: 1000
    }).addTo(this.map);
    
    // Hide initially
    positionMarker.setLatLng([0,0]);
    positionMarker.setStyle({opacity: 0, fillOpacity: 0});

    // Create Chart
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [{
          label: 'Elevation',
          data: data,
          borderColor: '#2563eb',
          backgroundColor: (context) => {
            const ctx = context.chart.ctx;
            const gradient = ctx.createLinearGradient(0, 0, 0, 400);
            gradient.addColorStop(0, 'rgba(37, 99, 235, 0.5)');
            gradient.addColorStop(1, 'rgba(37, 99, 235, 0.0)');
            return gradient;
          },
          borderWidth: 2,
          pointRadius: 0, // Hide points normally
          pointHoverRadius: 6,
          pointHoverBackgroundColor: '#2563eb',
          pointHoverBorderColor: '#fff',
          pointHoverBorderWidth: 2,
          fill: true,
          tension: 0.1 // Slight curve smoothing
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
            backgroundColor: 'rgba(15, 23, 42, 0.9)',
            titleColor: '#94a3b8',
            bodyColor: '#fff',
            titleFont: { size: 10 },
            bodyFont: { size: 14, weight: 'bold' },
            padding: 10,
            cornerRadius: 8,
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
            title: { display: true, text: 'Distance (km)', color: '#94a3b8', font: {size: 10} },
            grid: { display: false },
            ticks: { color: '#94a3b8', font: {size: 10} }
          },
          y: {
            title: { display: true, text: 'Elevation (m)', color: '#94a3b8', font: {size: 10} },
            grid: { color: '#f1f5f9' },
            ticks: { color: '#94a3b8', font: {size: 10} }
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

  // Haversine formula for distance in km
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

