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

    if (navigator.geolocation) {
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
          
          button.textContent = 'Location captured!'
          setTimeout(() => {
            button.textContent = originalText
            button.disabled = false
          }, 2000)
        },
        (error) => {
          console.error('Geolocation error:', error)
          button.textContent = 'Location failed'
          setTimeout(() => {
            button.textContent = originalText
            button.disabled = false
          }, 2000)
        }
      )
    } else {
      button.textContent = 'Location not available'
      setTimeout(() => {
        button.textContent = originalText
        button.disabled = false
      }, 2000)
    }
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