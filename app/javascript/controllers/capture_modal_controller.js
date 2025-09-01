import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="capture-modal"
export default class extends Controller {
  static targets = ["modal", "advancedOptions"]

  connect() {
    // Close modal when clicking outside
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener('click', this.boundCloseOnOutsideClick)
  }

  open(event) {
    event.preventDefault()
    this.modalTarget.classList.remove('hidden')
    this.modalTarget.classList.add('flex')
    document.body.style.overflow = 'hidden'
    
    // Focus on the content textarea
    const textarea = this.modalTarget.querySelector('textarea')
    if (textarea) {
      textarea.focus()
    }

    // Automatically get current location when modal opens
    this.getLocationOnOpen()

    // Add outside click listener
    setTimeout(() => {
      document.addEventListener('click', this.boundCloseOnOutsideClick)
    }, 100)
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add('hidden')
    this.modalTarget.classList.remove('flex')
    document.body.style.overflow = 'auto'
    document.removeEventListener('click', this.boundCloseOnOutsideClick)
  }

  closeOnOutsideClick(event) {
    const modalContent = this.modalTarget.querySelector('.modal-content')
    if (modalContent && !modalContent.contains(event.target)) {
      this.close()
    }
  }

  toggleAdvanced(event) {
    event.preventDefault()
    this.advancedOptionsTarget.classList.toggle('hidden')
    const button = event.currentTarget
    const isHidden = this.advancedOptionsTarget.classList.contains('hidden')
    button.textContent = isHidden ? 'Show more options' : 'Hide options'
  }

  getCurrentLocation(event) {
    event.preventDefault()
    const button = event.currentTarget
    const originalText = button.textContent
    
    button.textContent = 'Getting location...'
    button.disabled = true

    // Try precise GPS location first, then fallback to IP-based
    if (navigator.geolocation) {
      const options = {
        enableHighAccuracy: true,
        timeout: 5000,
        maximumAge: 60000 // 1 minute cache for manual requests
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords
          
          // Fill in the coordinate fields
          const latField = this.element.querySelector('[data-location-target="latitude"]')
          const lngField = this.element.querySelector('[data-location-target="longitude"]')
          
          if (latField) latField.value = latitude
          if (lngField) lngField.value = longitude
          
          // Try to get address from coordinates (reverse geocoding)
          this.reverseGeocode(latitude, longitude)
          
          button.textContent = 'Precise location captured!'
          setTimeout(() => {
            button.textContent = originalText
            button.disabled = false
          }, 2000)
        },
        (error) => {
          console.log('Precise location failed, using IP location:', error.message)
          // Fallback to IP-based location with user feedback
          this.getIPBasedLocationWithFeedback(button, originalText)
        },
        options
      )
    } else {
      // No geolocation support, use IP-based location
      this.getIPBasedLocationWithFeedback(button, originalText)
    }
  }

  getIPBasedLocationWithFeedback(button, originalText) {
    fetch('https://api.bigdatacloud.net/data/client-info')
      .then(response => response.json())
      .then(data => {
        if (data.location && data.location.latitude && data.location.longitude) {
          const latField = this.element.querySelector('[data-location-target="latitude"]')
          const lngField = this.element.querySelector('[data-location-target="longitude"]')
          const locationField = this.element.querySelector('[data-location-target="locationName"]')
          
          if (latField) latField.value = data.location.latitude
          if (lngField) lngField.value = data.location.longitude
          if (locationField && data.location.city) {
            locationField.value = data.location.city + (data.location.principalSubdivision ? `, ${data.location.principalSubdivision}` : '')
          }
          
          button.textContent = 'City location captured!'
        } else {
          button.textContent = 'Location failed'
        }
        
        setTimeout(() => {
          button.textContent = originalText
          button.disabled = false
        }, 2000)
      })
      .catch(error => {
        console.log('IP-based location failed:', error)
        button.textContent = 'Location failed'
        setTimeout(() => {
          button.textContent = originalText
          button.disabled = false
        }, 2000)
      })
  }

  getLocationOnOpen() {
    // Use IP-based location as primary method to avoid permission prompts and rate limits
    this.getIPBasedLocation()
  }

  getIPBasedLocation() {
    // Use IP-based location service as fallback
    fetch('https://api.bigdatacloud.net/data/client-info')
      .then(response => response.json())
      .then(data => {
        if (data.location && data.location.latitude && data.location.longitude) {
          const latField = this.element.querySelector('[data-location-target="latitude"]')
          const lngField = this.element.querySelector('[data-location-target="longitude"]')
          const locationField = this.element.querySelector('[data-location-target="locationName"]')
          
          if (latField) latField.value = data.location.latitude
          if (lngField) lngField.value = data.location.longitude
          if (locationField && data.location.city) {
            locationField.value = data.location.city + (data.location.principalSubdivision ? `, ${data.location.principalSubdivision}` : '')
          }
        }
      })
      .catch(error => {
        console.log('IP-based location failed:', error)
        // Silently fail - user can still manually get location if needed
      })
  }

  reverseGeocode(lat, lng) {
    // Simple reverse geocoding using a free service
    fetch(`https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lng}&localityLanguage=en`)
      .then(response => response.json())
      .then(data => {
        const locationField = this.element.querySelector('[data-location-target="locationName"]')
        if (locationField && data.locality) {
          locationField.value = data.locality + (data.principalSubdivision ? `, ${data.principalSubdivision}` : '')
        }
      })
      .catch(error => {
        console.log('Reverse geocoding failed:', error)
      })
  }
}