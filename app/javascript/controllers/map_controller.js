import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
  static values = { 
    entries: Array,
    center: Array,
    zoom: Number 
  }
  static targets = ["container"]

  connect() {
    this.initializeMap()
    this.addMarkers()
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }

  initializeMap() {
    // Default center (will be overridden by data)
    const defaultCenter = this.centerValue || [40.7128, -74.0060] // NYC
    const defaultZoom = this.zoomValue || 10

    this.map = L.map(this.containerTarget, {
      attributionControl: true
    }).setView(defaultCenter, defaultZoom)

    // Add OpenStreetMap tiles
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(this.map)
  }

  addMarkers() {
    if (!this.entriesValue || this.entriesValue.length === 0) return

    const validEntries = this.entriesValue.filter(entry => 
      entry.latitude && entry.longitude
    )

    if (validEntries.length === 0) return

    // Create marker group
    const group = new L.FeatureGroup()

    validEntries.forEach(entry => {
      // Create custom icon for favorites
      const icon = entry.favorite ? 
        this.createCustomIcon('⭐', '#fbbf24') : 
        this.createCustomIcon('📍', '#10b981')

      const marker = L.marker([entry.latitude, entry.longitude], { icon })
        .bindPopup(this.createPopupContent(entry))
      
      group.addLayer(marker)
    })

    group.addTo(this.map)

    // Fit map to show all markers
    if (validEntries.length > 1) {
      this.map.fitBounds(group.getBounds(), { padding: [20, 20] })
    } else {
      this.map.setView([validEntries[0].latitude, validEntries[0].longitude], 15)
    }
  }

  createCustomIcon(emoji, color) {
    return L.divIcon({
      className: 'custom-marker',
      html: `
        <div style="
          background: ${color};
          width: 40px;
          height: 40px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 20px;
          border: 3px solid white;
          box-shadow: 0 2px 8px rgba(0,0,0,0.3);
        ">${emoji}</div>
      `,
      iconSize: [40, 40],
      iconAnchor: [20, 20],
      popupAnchor: [0, -20]
    })
  }

  createPopupContent(entry) {
    const date = new Date(entry.entry_date).toLocaleDateString()
    const favoriteIcon = entry.favorite ? '⭐ ' : ''
    
    return `
      <div class="p-2 max-w-xs">
        <div class="font-bold text-emerald-800 mb-2">
          ${favoriteIcon}${date}
        </div>
        ${entry.location ? `<div class="text-sm text-emerald-600 mb-2">📍 ${entry.location}</div>` : ''}
        <div class="text-sm text-emerald-900 leading-relaxed">
          ${entry.content.substring(0, 150)}${entry.content.length > 150 ? '...' : ''}
        </div>
        ${entry.image_url ? `<img src="${entry.image_url}" class="mt-2 rounded-lg max-w-full h-24 object-cover" />` : ''}
      </div>
    `
  }
}