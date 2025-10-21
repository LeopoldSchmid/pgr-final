import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="page-transition"
export default class extends Controller {
  connect() {
    // Add initial page load animation
    this.animatePageIn()

    // Listen to Turbo navigation events
    document.addEventListener('turbo:before-visit', this.beforeVisit.bind(this))
    document.addEventListener('turbo:load', this.pageLoaded.bind(this))
    document.addEventListener('turbo:before-render', this.beforeRender.bind(this))
  }

  disconnect() {
    document.removeEventListener('turbo:before-visit', this.beforeVisit.bind(this))
    document.removeEventListener('turbo:load', this.pageLoaded.bind(this))
    document.removeEventListener('turbo:before-render', this.beforeRender.bind(this))
  }

  beforeVisit(event) {
    // Optional: Add a fade-out effect before navigation
    // Only if user doesn't prefer reduced motion
    if (!this.prefersReducedMotion()) {
      document.body.style.opacity = '1'
    }
  }

  beforeRender(event) {
    // Prepare the new content for animation
    if (!this.prefersReducedMotion()) {
      const newBody = event.detail.newBody
      newBody.style.opacity = '0'
    }
  }

  pageLoaded(event) {
    // Animate the page in after Turbo has loaded new content
    this.animatePageIn()
  }

  animatePageIn() {
    if (this.prefersReducedMotion()) {
      return
    }

    // Fade in the page
    requestAnimationFrame(() => {
      document.body.style.transition = 'opacity 0.3s ease-out'
      document.body.style.opacity = '1'
    })

    // Animate main content if it exists
    const mainContent = document.querySelector('main')
    if (mainContent) {
      mainContent.style.animation = 'slideUp 0.4s ease-out'
    }
  }

  prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
  }
}
