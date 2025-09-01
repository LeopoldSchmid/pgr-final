import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="capture-modal"
export default class extends Controller {
  static targets = ["modal", "advancedOptions", "locationName", "latitude", "longitude", "autocompleteResults"]

  connect() {
    // Close modal when clicking outside (for modal usage)
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
    
    // Initialize location search debounce timer
    this.debounceTimer = null
    
    // Initialize location state tracking
    this.locationSources = []
    this.locationAttempts = {
      gps: false,
      ip: false
    }
    
    // Initialize retry mechanism
    this.retryCount = 0
    this.maxRetries = 2
    
    // Initialize geolocation rate limiting
    this.geolocationAttempts = this.getGeolocationAttempts()
    this.maxGeolocationAttempts = 3 // Max 3 attempts per 10 minutes
    
    // Initialize offline capabilities
    this.offlineMode = !navigator.onLine
    this.setupOfflineCapabilities()
    
    // Mobile-specific initialization
    this.isMobile = this.detectMobile()
    this.setupMobileOptimizations()
    
    // Auto-start location detection when controller loads (for both modal and page usage)
    this.initiateHierarchicalLocationDetection()
  }

  setupOfflineCapabilities() {
    // Listen for online/offline events
    window.addEventListener('online', this.handleOnline.bind(this))
    window.addEventListener('offline', this.handleOffline.bind(this))
    
    // Check for cached offline locations on load
    this.loadOfflineLocations()
  }

  handleOnline() {
    console.log('Connection restored - syncing offline data')
    this.offlineMode = false
    this.showErrorNotification(
      'Connection Restored',
      'Syncing any offline data...',
      'success'
    )
    
    // Trigger sync if service worker is available
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.ready.then(registration => {
        if ('sync' in registration) {
          registration.sync.register('location-sync')
          registration.sync.register('journal-sync')
        }
      })
    }
  }

  handleOffline() {
    console.log('Connection lost - enabling offline mode')
    this.offlineMode = true
    this.showErrorNotification(
      'You\'re Offline',
      'Your memories will be saved and synced when you\'re back online.',
      'info'
    )
  }

  async loadOfflineLocations() {
    // Load any cached offline locations to provide as fallback
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.ready
        if (registration.active) {
          const messageChannel = new MessageChannel()
          
          messageChannel.port1.onmessage = (event) => {
            if (event.data.success && event.data.data.length > 0) {
              this.cachedOfflineLocations = event.data.data
              console.log('Loaded offline location cache:', this.cachedOfflineLocations.length, 'entries')
            }
          }
          
          registration.active.postMessage(
            { action: 'get-offline-locations' },
            [messageChannel.port2]
          )
        }
      } catch (error) {
        console.log('Could not load offline locations:', error)
      }
    }
  }

  async storeOfflineLocation(locationData) {
    // Store location data for offline use via service worker
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.ready
        if (registration.active) {
          registration.active.postMessage({
            action: 'store-offline-location',
            locationData: {
              latitude: locationData.latitude,
              longitude: locationData.longitude,
              source: locationData.source,
              accuracy: locationData.accuracy,
              timestamp: new Date().toISOString()
            }
          })
        }
      } catch (error) {
        console.log('Could not store offline location:', error)
      }
    }
  }

  async getOfflineLocationFallback() {
    // Use the most recent offline location as a fallback
    if (this.cachedOfflineLocations && this.cachedOfflineLocations.length > 0) {
      // Sort by timestamp and get the most recent
      const sortedLocations = this.cachedOfflineLocations.sort(
        (a, b) => new Date(b.timestamp) - new Date(a.timestamp)
      )
      
      const recentLocation = sortedLocations[0]
      const age = Date.now() - new Date(recentLocation.timestamp).getTime()
      
      // Only use cached location if it's less than 24 hours old
      if (age < 24 * 60 * 60 * 1000) {
        this.updateLocationFields(
          recentLocation.latitude,
          recentLocation.longitude,
          `Offline_${recentLocation.source}`
        )
        
        // Show user that we're using cached location
        this.showErrorNotification(
          'Using Cached Location',
          'Using your last known location while offline.',
          'info'
        )
        
        return true
      }
    }
    
    return false
  }

  getGeolocationAttempts() {
    // Get recent geolocation attempts from localStorage to prevent rate limiting
    try {
      const stored = localStorage.getItem('geolocationAttempts')
      if (stored) {
        const attempts = JSON.parse(stored)
        // Filter to only include attempts from last 10 minutes
        const tenMinutesAgo = Date.now() - (10 * 60 * 1000)
        return attempts.filter(timestamp => timestamp > tenMinutesAgo)
      }
    } catch (error) {
      console.log('Could not read geolocation attempts:', error)
    }
    return []
  }

  recordGeolocationAttempt() {
    // Record a new geolocation attempt
    try {
      this.geolocationAttempts.push(Date.now())
      // Keep only last 10 attempts
      this.geolocationAttempts = this.geolocationAttempts.slice(-10)
      localStorage.setItem('geolocationAttempts', JSON.stringify(this.geolocationAttempts))
    } catch (error) {
      console.log('Could not record geolocation attempt:', error)
    }
  }

  canUseGeolocation() {
    // Check if we can safely use geolocation without hitting rate limits
    const recentAttempts = this.getGeolocationAttempts()
    if (recentAttempts.length >= this.maxGeolocationAttempts) {
      console.log('Geolocation rate limited - too many recent attempts')
      return false
    }
    return true
  }

  detectMobile() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
           (navigator.maxTouchPoints > 0 && window.innerWidth < 768)
  }

  setupMobileOptimizations() {
    if (this.isMobile) {
      // Add mobile-specific classes and behaviors
      this.element.classList.add('mobile-optimized')
      
      // Prevent zoom on input focus for iOS
      const inputs = this.element.querySelectorAll('input[type="text"]')
      inputs.forEach(input => {
        input.addEventListener('focus', this.preventZoom.bind(this))
        input.addEventListener('blur', this.restoreZoom.bind(this))
      })
    }
  }

  preventZoom(event) {
    // Prevent iOS zoom on input focus by temporarily setting font-size
    if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
      event.target.style.fontSize = '16px'
    }
  }

  restoreZoom(event) {
    // Restore original font size after blur
    if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
      event.target.style.fontSize = ''
    }
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

  async getCurrentLocation(event) {
    event.preventDefault()
    const button = event.currentTarget
    const originalText = button.textContent
    
    // Check if we're rate limited
    if (!this.canUseGeolocation()) {
      this.showErrorNotification(
        'Location Temporarily Limited', 
        'Please wait a few minutes before trying GPS location again. You can still enter your location manually.',
        'warning'
      )
      return
    }
    
    button.textContent = 'Getting location...'
    button.disabled = true

    // For manual requests, try GPS first (user explicitly requested it)
    const gpsSuccess = await this.tryGPSLocation()
    if (gpsSuccess) {
      button.textContent = '✓ GPS location'
    } else {
      // Fall back to IP location
      const ipSuccess = await this.tryIPLocation()
      if (ipSuccess) {
        button.textContent = '✓ IP location'
      } else {
        button.textContent = 'Location failed'
      }
    }
    
    // Reset button state
    setTimeout(() => {
      button.textContent = originalText
      button.disabled = false
    }, 2000)
  }


  async initiateHierarchicalLocationDetection() {
    // NEW STRATEGY: IP First → GPS Enhancement → Offline Cache → Manual
    // This avoids browser geolocation rate limits by making IP primary
    console.log('Starting IP-first location detection...')
    
    // Step 1: Try IP-based location FIRST (most reliable, no rate limits)
    if (!this.offlineMode) {
      const ipSuccess = await this.tryIPLocation()
      if (ipSuccess) {
        console.log('IP location successful')
        this.storeOfflineLocation({
          latitude: this.element.querySelector('[data-location-target="latitude"]').value,
          longitude: this.element.querySelector('[data-location-target="longitude"]').value,
          source: 'IP'
        })
        
        // Now try to enhance with GPS in background (non-blocking)
        this.tryGPSEnhancement()
        return
      }
    }
    
    // Step 2: Try offline cached location if IP failed or we're offline
    if (this.offlineMode || this.locationSources.length === 0) {
      const offlineSuccess = await this.getOfflineLocationFallback()
      if (offlineSuccess) {
        console.log('Offline cached location successful')
        return
      }
    }
    
    // Step 3: Only try browser geolocation as last resort (to avoid rate limits)
    console.log('Trying browser geolocation as last resort...')
    const gpsSuccess = await this.tryGPSLocation()
    if (gpsSuccess) {
      console.log('GPS location successful')
      this.storeOfflineLocation({
        latitude: this.element.querySelector('[data-location-target="latitude"]').value,
        longitude: this.element.querySelector('[data-location-target="longitude"]').value,
        source: 'GPS',
        accuracy: this.lastLocationAccuracy
      })
      return
    }
    
    // Step 4: All methods failed - user needs to enter manually
    console.log('All automatic location methods failed - manual entry required')
    this.showLocationFailureMessage()
  }

  async tryGPSEnhancement() {
    // Try to enhance IP location with GPS, but don't block on it
    setTimeout(async () => {
      try {
        console.log('Attempting GPS enhancement...')
        const gpsSuccess = await this.tryGPSLocation()
        if (gpsSuccess) {
          console.log('GPS enhancement successful - upgraded location precision')
          this.showErrorNotification(
            'Location Enhanced', 
            'Upgraded to precise GPS location!', 
            'success'
          )
        }
      } catch (error) {
        console.log('GPS enhancement failed (this is normal):', error)
      }
    }, 1000) // Small delay to let IP location show first
  }

  async tryGPSLocation() {
    if (!navigator.geolocation) return false
    
    // Check if we're rate limited before attempting
    if (!this.canUseGeolocation()) {
      console.log('Skipping GPS location - rate limited')
      return false
    }
    
    this.locationAttempts.gps = true
    this.recordGeolocationAttempt()
    
    try {
      // Check permission status first
      const permission = await navigator.permissions.query({name: 'geolocation'})
      if (permission.state === 'denied') return false
      
      return new Promise((resolve) => {
        // Mobile-optimized GPS options
        const options = {
          enableHighAccuracy: true,
          timeout: this.isMobile ? 15000 : 12000, // Increased timeout for better reliability
          maximumAge: this.isMobile ? 300000 : 600000 // More reasonable cache duration
        }

        navigator.geolocation.getCurrentPosition(
          (position) => {
            const { latitude, longitude, accuracy } = position.coords
            
            // Store accuracy information for mobile users
            this.lastLocationAccuracy = accuracy
            
            this.updateLocationFields(latitude, longitude, 'GPS_Auto')
            this.reverseGeocode(latitude, longitude)
            this.locationSources.push('GPS')
            this.showLocationSourceIndicator('GPS', 'success', accuracy)
            resolve(true)
          },
          (error) => {
            console.log('GPS location failed:', error.message)
            this.handleLocationError('GPS', error)
            this.showLocationSourceIndicator('GPS', 'failed')
            resolve(false)
          },
          options
        )
      })
    } catch (error) {
      console.log('GPS permission check failed:', error)
      return false
    }
  }

  // Device location removed - was hitting same rate limits as GPS

  async tryIPLocation() {
    this.locationAttempts.ip = true
    
    // Try primary IP location service first
    try {
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 5000) // 5 second timeout
      
      const response = await fetch('https://api.bigdatacloud.net/data/client-info', {
        signal: controller.signal
      })
      clearTimeout(timeoutId)
      
      if (response.ok) {
        const data = await response.json()
        
        if (data.location && data.location.latitude && data.location.longitude) {
          this.updateLocationFields(data.location.latitude, data.location.longitude, 'IP')
          
          const locationField = this.element.querySelector('[data-location-target="locationName"]')
          if (locationField && data.location.city) {
            locationField.value = data.location.city + (data.location.principalSubdivision ? `, ${data.location.principalSubdivision}` : '')
          }
          
          this.locationSources.push('IP')
          this.showLocationSourceIndicator('IP', 'success')
          return true
        }
      }
    } catch (error) {
      console.log('Primary IP location service failed:', error)
      
      // Try backup IP location service
      try {
        const controller = new AbortController()
        const timeoutId = setTimeout(() => controller.abort(), 5000)
        
        const response = await fetch('https://ipapi.co/json/', {
          signal: controller.signal
        })
        clearTimeout(timeoutId)
        
        if (response.ok) {
          const data = await response.json()
          
          if (data.latitude && data.longitude && !data.error) {
            this.updateLocationFields(data.latitude, data.longitude, 'IP_Backup')
            
            const locationField = this.element.querySelector('[data-location-target="locationName"]')
            if (locationField && data.city) {
              locationField.value = data.city + (data.region ? `, ${data.region}` : '')
            }
            
            this.locationSources.push('IP')
            this.showLocationSourceIndicator('IP', 'success')
            return true
          }
        }
      } catch (backupError) {
        console.log('Backup IP location service failed:', backupError)
        this.handleNetworkError('IP Location', backupError)
        this.showLocationSourceIndicator('IP', 'failed')
      }
    }
    
    return false
  }

  showLocationSourceIndicator(source, status, accuracy = null) {
    // Provide subtle visual feedback about which location method was used
    const gpsButton = this.element.querySelector('[data-action*="getCurrentLocation"]')
    if (gpsButton && status === 'success') {
      const statusEmoji = {
        'GPS_Auto': '🎯',
        'GPS': '🎯', 
        'Device': '📍',
        'IP': '🌐'
      }
      
      const originalText = gpsButton.textContent
      let displayText = `${statusEmoji[source] || '📍'} ${source}`
      
      // Add accuracy information for mobile users
      if (this.isMobile && accuracy && source.includes('GPS')) {
        const accuracyText = accuracy < 10 ? 'Precise' : accuracy < 50 ? 'Good' : 'OK'
        displayText = this.isMobile ? `${statusEmoji[source]} ${accuracyText}` : displayText
      }
      
      gpsButton.textContent = displayText
      
      if (source.includes('GPS')) {
        gpsButton.classList.add('bg-green-500', 'hover:bg-green-600')
        gpsButton.classList.remove('bg-primary-accent', 'hover:bg-blue-600')
      } else if (source === 'Device') {
        gpsButton.classList.add('bg-yellow-500', 'hover:bg-yellow-600')
        gpsButton.classList.remove('bg-primary-accent', 'hover:bg-blue-600')
      } else if (source === 'IP') {
        gpsButton.classList.add('bg-orange-500', 'hover:bg-orange-600')
        gpsButton.classList.remove('bg-primary-accent', 'hover:bg-blue-600')
      }
      
      setTimeout(() => {
        gpsButton.textContent = originalText
        gpsButton.classList.remove('bg-green-500', 'hover:bg-green-600', 'bg-yellow-500', 'hover:bg-yellow-600', 'bg-orange-500', 'hover:bg-orange-600')
        gpsButton.classList.add('bg-primary-accent', 'hover:bg-blue-600')
      }, this.isMobile ? 5000 : 4000) // Slightly longer display time on mobile
    }
  }

  handleLocationError(source, error) {
    // Comprehensive error handling with user-friendly messages
    let title, message, type = 'error'
    
    switch (error.code) {
      case error.PERMISSION_DENIED:
        title = 'Location Access Denied'
        message = this.isMobile 
          ? 'Please enable location permissions in your browser settings to automatically capture your location.'
          : 'Location access was denied. Please enable location permissions and try again.'
        type = 'warning'
        break
        
      case error.POSITION_UNAVAILABLE:
        title = 'Location Unavailable'
        message = this.isMobile 
          ? 'Cannot determine your location. Please check that location services are enabled on your device.'
          : 'Location information is unavailable. Please check your device\'s location settings.'
        type = 'warning'
        break
        
      case error.TIMEOUT:
        title = 'Location Request Timed Out'
        message = this.isMobile 
          ? 'Location request took too long. Please ensure you have a good signal and try again.'
          : 'Location request timed out. Please try again or enter location manually.'
        type = 'warning'
        break
        
      default:
        title = `${source} Location Failed`
        message = 'An unexpected error occurred while getting your location. You can still enter your location manually.'
        break
    }
    
    // Only show error notification for GPS failures that are likely user-actionable
    if (source === 'GPS' && error.code === error.PERMISSION_DENIED) {
      this.showErrorNotification(title, message, type)
    } else {
      // For other errors, just log them - they're part of normal fallback flow
      console.log(`${source} location error:`, title, message)
    }
    
    // Track error for potential retry logic
    this.lastLocationError = { source, error, timestamp: Date.now() }
  }

  shouldRetryLocation() {
    // Only retry if we have no location sources at all and it's been a while
    if (this.retryCount >= this.maxRetries) return false
    if (this.locationSources.length > 0) return false // We got something, don't retry
    if (!this.lastLocationError) return false
    
    // Don't retry if user explicitly denied permissions
    if (this.lastLocationError.error && this.lastLocationError.error.code === GeolocationPositionError.PERMISSION_DENIED) return false
    
    // Only retry after a longer delay to avoid spamming
    if (Date.now() - this.lastLocationError.timestamp < 10000) return false // 10 second wait
    
    // Only retry if we're online (no point retrying IP location when offline)
    if (this.offlineMode) return false
    
    return true
  }

  async retryLocationDetection() {
    if (!this.shouldRetryLocation()) return false
    
    this.retryCount++
    console.log(`Retrying location detection (attempt ${this.retryCount}/${this.maxRetries})`)
    
    // Show retry notification
    this.showErrorNotification(
      'Retrying location detection...',
      `Attempt ${this.retryCount} of ${this.maxRetries}`,
      'info'
    )
    
    // Reset attempts for retry
    this.locationAttempts = { gps: false, ip: false }
    this.locationSources = []
    
    await this.initiateHierarchicalLocationDetection()
    return true
  }

  showLocationFailureMessage() {
    // Show a helpful message when all location methods fail
    const locationField = this.element.querySelector('[data-location-target="locationName"]')
    if (locationField) {
      locationField.placeholder = "Please enter your location manually"
      locationField.classList.add('border-red-300', 'focus:border-red-500')
    }
    
    const gpsButton = this.element.querySelector('[data-action*="getCurrentLocation"]')
    if (gpsButton) {
      gpsButton.textContent = 'Retry Location'
      gpsButton.classList.add('bg-red-500', 'hover:bg-red-600')
      gpsButton.classList.remove('bg-primary-accent', 'hover:bg-blue-600')
    }
    
    // Only show notification if we truly have no location at all
    if (this.locationSources.length === 0) {
      this.showErrorNotification(
        'Location detection not available', 
        'You can enter your location manually or try the location button.', 
        'info'
      )
    }
  }

  showErrorNotification(title, message, type = 'info') {
    // Create a user-friendly notification system
    const notification = document.createElement('div')
    notification.classList.add(
      'fixed', 'top-4', 'right-4', 'max-w-sm', 'rounded-lg', 'shadow-lg', 'p-4', 'z-50',
      'transform', 'transition-all', 'duration-300', 'translate-x-full'
    )
    
    // Style based on type
    if (type === 'error') {
      notification.classList.add('bg-red-100', 'border', 'border-red-400', 'text-red-700')
    } else if (type === 'warning') {
      notification.classList.add('bg-yellow-100', 'border', 'border-yellow-400', 'text-yellow-700')
    } else if (type === 'success') {
      notification.classList.add('bg-green-100', 'border', 'border-green-400', 'text-green-700')
    } else {
      notification.classList.add('bg-blue-100', 'border', 'border-blue-400', 'text-blue-700')
    }
    
    notification.innerHTML = `
      <div class="flex items-start">
        <div class="flex-shrink-0">
          ${this.getNotificationIcon(type)}
        </div>
        <div class="ml-3 flex-1">
          <h3 class="text-sm font-medium">${title}</h3>
          <p class="mt-1 text-sm">${message}</p>
        </div>
        <button class="ml-4 flex-shrink-0 text-sm hover:opacity-75" onclick="this.parentElement.parentElement.remove()">
          ✕
        </button>
      </div>
    `
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.classList.remove('translate-x-full')
    }, 10)
    
    // Auto-remove after delay
    setTimeout(() => {
      if (notification.parentElement) {
        notification.classList.add('translate-x-full')
        setTimeout(() => {
          notification.remove()
        }, 300)
      }
    }, this.isMobile ? 6000 : 5000) // Longer display on mobile
  }

  getNotificationIcon(type) {
    const icons = {
      error: '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>',
      warning: '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>',
      success: '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>',
      info: '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>'
    }
    return icons[type] || icons.info
  }

  handleNetworkError(operation, error) {
    // Handle network-related errors (API calls, etc.) - but be less noisy about expected failures
    let title, message
    
    if (!navigator.onLine) {
      title = 'No Internet Connection'
      message = `Cannot ${operation.toLowerCase()} while offline.`
    } else if (error.name === 'AbortError') {
      // Timeout is normal, don't show error
      console.log(`${operation} timed out - this is normal during fallback`)
      return
    } else if (error.name === 'TypeError' && error.message.includes('Failed to fetch')) {
      title = 'Network Error'
      message = `Unable to complete ${operation.toLowerCase()}.`
    } else {
      title = `${operation} Error`
      message = `An error occurred during ${operation.toLowerCase()}.`
    }
    
    // Only show network error notifications for offline scenarios or on final retry
    if (!navigator.onLine || (this.retryCount >= this.maxRetries && this.locationSources.length === 0)) {
      this.showErrorNotification(title, message, 'warning')
    } else {
      console.log(`${operation} failed:`, title, message)
    }
  }


  updateLocationFields(latitude, longitude, source) {
    const latField = this.element.querySelector('[data-location-target="latitude"]')
    const lngField = this.element.querySelector('[data-location-target="longitude"]')
    
    // Use high precision for GPS sources, moderate precision for others
    const precision = source.includes('GPS') ? 8 : 6
    
    if (latField) {
      latField.value = parseFloat(latitude).toFixed(precision)
      latField.dataset.locationSource = source
    }
    if (lngField) {
      lngField.value = parseFloat(longitude).toFixed(precision)
      lngField.dataset.locationSource = source
    }
  }


  async reverseGeocode(lat, lng) {
    try {
      // Use OpenStreetMap's Nominatim API for better reverse geocoding (from location_controller.js)
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=16&addressdetails=1`,
        {
          headers: {
            'User-Agent': 'PlanGoReminisce App'
          }
        }
      )
      
      if (response.ok) {
        const data = await response.json()
        const address = data.address || {}
        
        // Create a nice location name from the components (from location_controller.js)
        let locationName = ''
        
        if (address.amenity || address.shop || address.tourism) {
          locationName = address.amenity || address.shop || address.tourism
        } else if (address.house_number && address.road) {
          locationName = `${address.house_number} ${address.road}`
        } else if (address.road) {
          locationName = address.road
        } else if (address.neighbourhood || address.suburb) {
          locationName = address.neighbourhood || address.suburb
        } else if (address.city || address.town || address.village) {
          locationName = address.city || address.town || address.village
        }
        
        // Add city/area context if we have a specific place
        if (locationName && (address.city || address.town)) {
          locationName += `, ${address.city || address.town}`
        }
        
        const locationField = this.element.querySelector('[data-location-target="locationName"]')
        if (locationName && locationField) {
          locationField.value = locationName
          locationField.placeholder = locationName
        }
      }
    } catch (error) {
      console.log("Could not get location name, but coordinates saved:", error)
      // Don't show error notification for reverse geocoding - it's not critical
      // Coordinates are more important than the readable name
    }
  }

  // Location search and autocomplete functionality (from location_controller.js)
  search() {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      const locationField = this.element.querySelector('[data-location-target="locationName"]')
      if (locationField) {
        const query = locationField.value
        if (query.length > 2) { // Only search if query is at least 3 characters
          this.fetchAutocompleteResults(query)
        } else if (this.hasAutocompleteResultsTarget) {
          this.autocompleteResultsTarget.innerHTML = '' // Clear results if query is too short
          this.autocompleteResultsTarget.classList.add('hidden') // Hide container
        }
      }
    }, 300) // Debounce for 300ms
  }

  async fetchAutocompleteResults(query) {
    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=5`,
        {
          headers: {
            'User-Agent': 'PlanGoReminisce App'
          }
        }
      )

      if (response.ok) {
        const data = await response.json()
        this.displayAutocompleteResults(data)
      }
    } catch (error) {
      console.error("Autocomplete search error:", error)
      this.handleNetworkError('Location Search', error)
    }
  }

  displayAutocompleteResults(results) {
    if (!this.hasAutocompleteResultsTarget) return
    
    this.autocompleteResultsTarget.innerHTML = '' // Clear previous results
    
    if (results.length > 0) {
      this.autocompleteResultsTarget.classList.remove('hidden') // Show results container
      results.forEach(result => {
        const div = document.createElement('div')
        
        // Mobile-optimized touch target size and styling
        const baseClasses = ['cursor-pointer', 'text-text-primary', 'border-b', 'border-gray-300', 'active:bg-gray-300', 'touch-manipulation']
        const mobileClasses = this.isMobile ? ['p-4', 'text-base', 'hover:bg-gray-100'] : ['p-2', 'text-sm', 'hover:bg-gray-200']
        
        div.classList.add(...baseClasses, ...mobileClasses)
        div.textContent = result.display_name
        div.dataset.action = 'click->capture-modal#selectSuggestion touchend->capture-modal#selectSuggestion'
        div.dataset.latitude = result.lat
        div.dataset.longitude = result.lon
        div.dataset.locationName = result.display_name
        
        // Add mobile-friendly touch feedback
        if (this.isMobile) {
          div.addEventListener('touchstart', (e) => {
            e.currentTarget.classList.add('bg-gray-200')
          })
          div.addEventListener('touchend', (e) => {
            setTimeout(() => {
              e.currentTarget.classList.remove('bg-gray-200')
            }, 150)
          })
        }
        
        this.autocompleteResultsTarget.appendChild(div)
      })
    } else {
      const div = document.createElement('div')
      const classes = this.isMobile ? ['p-4', 'text-base'] : ['p-2', 'text-sm']
      div.classList.add('text-text-secondary', ...classes)
      div.textContent = 'No results found'
      this.autocompleteResultsTarget.appendChild(div)
      this.autocompleteResultsTarget.classList.remove('hidden') // Show even for "no results"
    }
  }

  selectSuggestion(event) {
    const locationField = this.element.querySelector('[data-location-target="locationName"]')
    if (locationField) {
      locationField.value = event.target.dataset.locationName
    }
    
    this.updateLocationFields(event.target.dataset.latitude, event.target.dataset.longitude, 'Search')
    
    if (this.hasAutocompleteResultsTarget) {
      this.autocompleteResultsTarget.innerHTML = '' // Clear results after selection
      this.autocompleteResultsTarget.classList.add('hidden') // Hide container
    }
  }

  // Mobile-specific event handlers
  handleTouchStart(event) {
    // Add haptic feedback for mobile devices (if supported)
    if (navigator.vibrate && this.isMobile) {
      navigator.vibrate(50) // 50ms vibration
    }
    
    // Add visual touch feedback
    event.currentTarget.classList.add('pressed')
    setTimeout(() => {
      event.currentTarget.classList.remove('pressed')
    }, 150)
  }

  handleFocus(event) {
    if (this.isMobile) {
      // Scroll field into view on mobile to prevent keyboard overlap
      setTimeout(() => {
        event.target.scrollIntoView({
          behavior: 'smooth',
          block: 'center'
        })
      }, 300) // Delay to allow keyboard animation
    }
  }

  handleBlur(event) {
    if (this.isMobile && this.hasAutocompleteResultsTarget) {
      // On mobile, add slight delay before hiding autocomplete to allow for touch selection
      setTimeout(() => {
        this.autocompleteResultsTarget.classList.add('hidden')
      }, 200)
    }
  }
}