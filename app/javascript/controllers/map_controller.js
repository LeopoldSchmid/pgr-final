import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    entries: Array,
    center: Array,
    zoom: Number 
  }
  static targets = ["container"]

  connect() {
    // Wait for Leaflet to be available
    this.waitForLeaflet().then(() => {
      this.initializeMap()
      this.addMarkers()
    }).catch(error => {
      console.error('Map initialization failed:', error)
      // Hide the map container or show an error message
      this.containerTarget.innerHTML = '<div class="bg-gray-100 rounded-xl p-8 text-center"><div class="text-gray-500">Map temporarily unavailable</div></div>'
    })
  }

  async waitForLeaflet() {
    // Wait for Leaflet to be loaded
    let attempts = 0
    const maxAttempts = 50
    
    while (typeof L === 'undefined' && attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 100))
      attempts++
    }
    
    if (typeof L === 'undefined') {
      console.error('Leaflet failed to load after 5 seconds')
      throw new Error('Leaflet is not available')
    }
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }

  initializeMap() {
    // Check if Leaflet is loaded globally
    if (typeof L === 'undefined') {
      console.error('Leaflet is not loaded')
      return
    }

    // Validate and set default center
    let center = [40.7128, -74.0060] // Default to NYC
    
    if (this.centerValue && Array.isArray(this.centerValue) && this.centerValue.length >= 2) {
      const lat = parseFloat(this.centerValue[0])
      const lng = parseFloat(this.centerValue[1])
      if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        center = [lat, lng]
      }
    }

    const zoom = this.zoomValue || 10

    this.map = L.map(this.containerTarget, {
      attributionControl: true
    }).setView(center, zoom)

    // Add OpenStreetMap tiles
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(this.map)
  }

  addMarkers() {
    if (!this.entriesValue || this.entriesValue.length === 0) return

    const validEntries = this.entriesValue.filter(entry => {
      const lat = parseFloat(entry.latitude)
      const lng = parseFloat(entry.longitude)
      return !isNaN(lat) && !isNaN(lng) && 
             lat >= -90 && lat <= 90 && 
             lng >= -180 && lng <= 180
    })

    if (validEntries.length === 0) return

    // Create marker group
    const group = new L.FeatureGroup()

    validEntries.forEach(entry => {
      const lat = parseFloat(entry.latitude)
      const lng = parseFloat(entry.longitude)
      
      // Create custom icon for favorites
      const icon = entry.favorite ? 
        this.createCustomIcon('⭐', '#fbbf24') : 
        this.createCustomIcon('📍', '#10b981')

      const marker = L.marker([lat, lng], { icon })
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