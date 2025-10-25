import { Controller } from "@hotwired/stimulus"

// Singleton to manage global Turbo events (only one instance listens)
class DirectionalTransitionManager {
  constructor() {
    if (DirectionalTransitionManager.instance) {
      return DirectionalTransitionManager.instance
    }
    DirectionalTransitionManager.instance = this
    this.setupGlobalListeners()
  }

  setupGlobalListeners() {
    if (this.listenersSetup) return
    this.listenersSetup = true

    document.addEventListener('turbo:before-visit', this.handleBeforeVisit.bind(this))
    document.addEventListener('turbo:before-render', this.handleBeforeRender.bind(this))
    document.addEventListener('turbo:render', this.handleRender.bind(this))
    document.addEventListener('turbo:load', this.handlePageLoad.bind(this))
  }

  handleBeforeVisit(event) {
    // Mark the current header to preserve its state
    const header = document.querySelector('#app-header')
    if (header) {
      header.style.visibility = 'visible'
      header.classList.add('turbo-permanent-preserving')
    }
  }

  handleBeforeRender(event) {
    const direction = sessionStorage.getItem('navDirection')
    const scope = sessionStorage.getItem('navScope')

    // CRITICAL: Prevent Turbo from replacing the permanent header
    // by keeping the old header and discarding the new one
    const currentHeader = document.querySelector('#app-header')
    const newBody = event.detail.newBody
    const newHeader = newBody.querySelector('#app-header')

    if (currentHeader && newHeader) {
      // Replace the new header with the current one to prevent any flashing
      // This ensures the exact same DOM element is preserved
      newHeader.replaceWith(currentHeader.cloneNode(true))
    }

    if (this.prefersReducedMotion()) return
    if (!direction) return

    // Hide overflow to prevent scrollbars during animation
    document.documentElement.style.overflowX = 'hidden'

    // Prepare animation for the new body
    const mainContent = newBody.querySelector('main')
    const secondaryNav = newBody.querySelector('nav[data-controller~="secondary-navigation"]')

    // Always animate main content
    if (mainContent) {
      // Set initial position based on direction
      const translateX = direction === 'right' ? '100%' : '-100%'
      mainContent.style.transform = `translateX(${translateX})`
      mainContent.style.opacity = '1'
      mainContent.style.transition = 'none'
    }

    // Only animate secondary nav if this is a PRIMARY navigation change
    if (secondaryNav && scope === 'primary') {
      const translateX = direction === 'right' ? '100%' : '-100%'
      secondaryNav.style.transform = `translateX(${translateX})`
      secondaryNav.style.opacity = '1'
      secondaryNav.style.transition = 'none'
    }
  }

  handleRender(event) {
    // Clean up after render
    const header = document.querySelector('#app-header')
    if (header) {
      header.classList.remove('turbo-permanent-preserving')
    }
  }

  handlePageLoad(event) {
    if (this.prefersReducedMotion()) return

    const direction = sessionStorage.getItem('navDirection')
    const scope = sessionStorage.getItem('navScope')

    // Animate the main content and secondary nav together
    const mainContent = document.querySelector('main')
    const secondaryNav = document.querySelector('nav[data-controller~="secondary-navigation"]')

    // Ensure permanent elements are never animated
    const header = document.querySelector('#app-header')
    if (header) {
      header.style.transform = ''
      header.style.opacity = ''
      header.style.transition = ''
    }

    if (direction && mainContent) {
      // Force a reflow
      void mainContent.offsetHeight
      if (secondaryNav && scope === 'primary') void secondaryNav.offsetHeight

      // Animate to final position
      const transition = 'transform 0.4s cubic-bezier(0.4, 0, 0.2, 1)'

      // Always animate main content
      mainContent.style.transition = transition
      mainContent.style.transform = 'translateX(0)'

      // Only animate secondary nav if this is a PRIMARY navigation change
      if (secondaryNav && scope === 'primary') {
        secondaryNav.style.transition = transition
        secondaryNav.style.transform = 'translateX(0)'
      }

      // Clean up
      setTimeout(() => {
        if (mainContent) {
          mainContent.style.transition = ''
          mainContent.style.transform = ''
          mainContent.style.opacity = ''
        }
        if (secondaryNav && scope === 'primary') {
          secondaryNav.style.transition = ''
          secondaryNav.style.transform = ''
          secondaryNav.style.opacity = ''
        }
        document.documentElement.style.overflowX = ''
      }, 400)
    } else {
      document.documentElement.style.overflowX = ''
    }

    // Clear the direction and scope
    sessionStorage.removeItem('navDirection')
    sessionStorage.removeItem('navScope')
  }

  prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
  }
}

// Initialize the singleton
new DirectionalTransitionManager()

// Connects to data-controller="directional-transition"
export default class extends Controller {
  connect() {
    // For primary nav links, check if we should redirect to a remembered secondary tab
    const isPrimary = !this.element.classList.contains('secondary-nav-item')
    if (isPrimary) {
      this.setupSmartRedirect()
    }
  }

  setupSmartRedirect() {
    // Store the original href
    const originalHref = this.element.getAttribute('href')
    this.element.dataset.originalHref = originalHref

    // Check if there's a remembered path for this primary nav item
    const rememberedPath = sessionStorage.getItem(`lastPath_${originalHref}`)
    if (rememberedPath) {
      this.element.setAttribute('href', rememberedPath)
    }
  }

  handleNavClick(event) {
    if (this.prefersReducedMotion()) return

    const newIndex = this.element.dataset.navIndex
    if (!newIndex) return

    // Determine scope (primary vs secondary)
    const scope = this.element.classList.contains('secondary-nav-item') ? 'secondary' : 'primary'
    const storageKey = `lastNavIndex_${scope}`
    const lastIndex = sessionStorage.getItem(storageKey)

    // Calculate direction and store new index
    if (lastIndex && newIndex !== lastIndex) {
      const direction = parseInt(newIndex) > parseInt(lastIndex) ? 'right' : 'left'
      sessionStorage.setItem('navDirection', direction)
      // Store the scope so we know if this was primary or secondary navigation
      sessionStorage.setItem('navScope', scope)
    }

    sessionStorage.setItem(storageKey, newIndex)

    // If this is a secondary nav click, remember the full path for the primary section
    if (scope === 'secondary') {
      const targetPath = this.element.getAttribute('href')
      // Find which primary section this belongs to and store the path
      const primaryPath = this.getPrimaryPathForCurrentSection()
      if (primaryPath) {
        sessionStorage.setItem(`lastPath_${primaryPath}`, targetPath)
      }
    }
  }

  getPrimaryPathForCurrentSection() {
    // Determine the primary path based on current URL
    const path = window.location.pathname

    if (path.includes('/trip') || path.includes('/discussions') || path.includes('/participants')) {
      return this.findPrimaryNavHref('trip')
    } else if (path.includes('/plans') || path.includes('/meals') || path.includes('/shopping') || path.includes('/packing') || path.includes('/itinerary')) {
      return this.findPrimaryNavHref('plans')
    } else if (path.includes('/memories') || path.includes('/albums') || path.includes('/map')) {
      return this.findPrimaryNavHref('memories')
    } else if (path.includes('/expenses')) {
      return this.findPrimaryNavHref('expenses')
    }

    return null
  }

  findPrimaryNavHref(section) {
    // Find the primary nav link for this section and return its original href
    const primaryLinks = document.querySelectorAll('[data-controller~="directional-transition"]:not(.secondary-nav-item)')

    for (const link of primaryLinks) {
      const href = link.dataset.originalHref || link.getAttribute('href')
      if (
        (section === 'trip' && (href.includes('/trip') || href.includes('/trips'))) ||
        (section === 'plans' && href.includes('/plans')) ||
        (section === 'memories' && href.includes('/memories')) ||
        (section === 'expenses' && href.includes('/expenses'))
      ) {
        return href
      }
    }

    return null
  }

  prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
  }
}
