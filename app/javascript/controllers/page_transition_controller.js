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

  beforeVisit() {
    // No body-level animations - directional transition controller handles content
  }

  beforeRender() {
    // No body-level animations - directional transition controller handles content
  }

  pageLoaded() {
    // No animations needed - directional transition controller handles content
  }

  animatePageIn() {
    // Disabled - directional transition controller handles all animations
  }

  prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
  }
}
