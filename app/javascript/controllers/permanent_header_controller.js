import { Controller } from "@hotwired/stimulus"

// Singleton to manage header persistence across Turbo navigation
class HeaderManager {
  constructor() {
    if (HeaderManager.instance) {
      return HeaderManager.instance
    }
    HeaderManager.instance = this
    this.cachedHeader = null
    this.setupListeners()
  }

  setupListeners() {
    if (this.listenersSetup) return
    this.listenersSetup = true

    // Store header before navigation
    document.addEventListener('turbo:before-visit', () => {
      const header = document.querySelector('#app-header')
      if (header) {
        this.cachedHeader = header.cloneNode(true)
      }
    })

    // Replace new header with cached one immediately
    document.addEventListener('turbo:before-render', (event) => {
      if (!this.cachedHeader) return

      const newBody = event.detail.newBody
      const newHeader = newBody.querySelector('#app-header')

      if (newHeader && this.cachedHeader) {
        // Replace the new header with cached one to prevent flash
        newHeader.parentNode.replaceChild(this.cachedHeader.cloneNode(true), newHeader)
      }
    })

    // Update cache after render
    document.addEventListener('turbo:render', () => {
      const header = document.querySelector('#app-header')
      if (header) {
        this.cachedHeader = header.cloneNode(true)
      }
    })
  }
}

// Initialize singleton
new HeaderManager()

// Connects to data-controller="permanent-header"
export default class extends Controller {
  connect() {
    // The singleton handles everything
  }
}
