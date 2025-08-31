import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["latitude", "longitude", "locationName", "button", "autocompleteResults"]

  connect() {
    this.debounceTimer = null;
  }

  getCurrentLocation(event) {
    event.preventDefault()
    
    if (!navigator.geolocation) {
      alert("Geolocation is not supported by this browser.")
      return
    }

    // Show loading state
    this.buttonTarget.textContent = "Getting location..."
    this.buttonTarget.disabled = true

    navigator.geolocation.getCurrentPosition(
      (position) => {
        console.log("Location success:", position)
        const { latitude, longitude } = position.coords
        
        // Set the coordinate fields with full precision (8 decimal places for ~1cm accuracy)
        this.latitudeTarget.value = latitude.toFixed(8)
        this.longitudeTarget.value = longitude.toFixed(8)
        
        // Show success message
        this.buttonTarget.textContent = "✅ Location captured!"
        this.buttonTarget.disabled = false
        
        // Try to get a human-readable location name
        this.reverseGeocode(latitude, longitude)
        
        // Reset button text after a delay
        setTimeout(() => {
          this.buttonTarget.textContent = "📍 Use Current Location"
        }, 2000)
      },
      (error) => {
        console.error("Geolocation error:", error)
        
        let errorMessage = "Could not get your current location. "
        switch(error.code) {
          case error.PERMISSION_DENIED:
            errorMessage += "Location access was denied. Please enable location permissions and try again."
            break
          case error.POSITION_UNAVAILABLE:
            errorMessage += "Location information is unavailable. Please check your device's location settings."
            break
          case error.TIMEOUT:
            errorMessage += "Location request timed out. Please try again."
            break
          default:
            errorMessage += "An unknown error occurred. Please try again or enter location manually."
            break
        }
        
        alert(errorMessage)
        
        // Reset button
        this.buttonTarget.textContent = "📍 Use Current Location"
        this.buttonTarget.disabled = false
      },
      {
        enableHighAccuracy: true,
        timeout: 15000, // Increased timeout to 15 seconds
        maximumAge: 60000 // Reduced to 1 minute for fresher location
      }
    )
  }

  async reverseGeocode(latitude, longitude) {
    try {
      // Use OpenStreetMap's Nominatim API for reverse geocoding (free!)
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=16&addressdetails=1`,
        {
          headers: {
            'User-Agent': 'PlanGoReminisce App'
          }
        }
      )
      
      if (response.ok) {
        const data = await response.json()
        const address = data.address || {}
        
        // Create a nice location name from the components
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
        
        if (locationName && this.hasLocationNameTarget) {
          this.locationNameTarget.value = locationName
          this.locationNameTarget.placeholder = locationName
        }
      }
    } catch (error) {
      console.log("Could not get location name, but coordinates saved:", error)
      // Silently fail - coordinates are more important than the name
    }
  }

  search() {
    clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      const query = this.locationNameTarget.value;
      if (query.length > 2) { // Only search if query is at least 3 characters
        this.fetchAutocompleteResults(query);
      } else {
        this.autocompleteResultsTarget.innerHTML = ''; // Clear results if query is too short
      }
    }, 300); // Debounce for 300ms
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
      );

      if (response.ok) {
        const data = await response.json();
        this.displayAutocompleteResults(data);
      }
    } catch (error) {
      console.error("Autocomplete search error:", error);
    }
  }

  displayAutocompleteResults(results) {
    this.autocompleteResultsTarget.innerHTML = ''; // Clear previous results
    if (results.length > 0) {
      results.forEach(result => {
        const div = document.createElement('div');
        div.classList.add('p-2', 'cursor-pointer', 'hover:bg-gray-200', 'text-text-primary', 'border-b', 'border-gray-300');
        div.textContent = result.display_name;
        div.dataset.action = 'click->location#selectSuggestion';
        div.dataset.latitude = result.lat;
        div.dataset.longitude = result.lon;
        div.dataset.locationName = result.display_name;
        this.autocompleteResultsTarget.appendChild(div);
      });
    } else {
      const div = document.createElement('div');
      div.classList.add('p-2', 'text-text-secondary');
      div.textContent = 'No results found';
      this.autocompleteResultsTarget.appendChild(div);
    }
  }

  selectSuggestion(event) {
    this.locationNameTarget.value = event.target.dataset.locationName;
    this.latitudeTarget.value = event.target.dataset.latitude;
    this.longitudeTarget.value = event.target.dataset.longitude;
    this.autocompleteResultsTarget.innerHTML = ''; // Clear results after selection
  }
}