import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal-animation"
// Add this controller to modal elements for smooth open/close animations
export default class extends Controller {
  static targets = ["backdrop", "content"]

  connect() {
    // Set initial state
    if (this.element.classList.contains('hidden')) {
      this.element.style.opacity = '0'
    }
  }

  open() {
    if (this.prefersReducedMotion()) {
      this.element.classList.remove('hidden')
      return
    }

    // Remove hidden class
    this.element.classList.remove('hidden')

    // Animate backdrop
    if (this.hasBackdropTarget) {
      this.backdropTarget.style.opacity = '0'
    }

    // Animate content
    if (this.hasContentTarget) {
      this.contentTarget.style.opacity = '0'
      this.contentTarget.style.transform = 'scale(0.95)'
    }

    // Trigger animations
    requestAnimationFrame(() => {
      this.element.style.transition = 'opacity 0.3s ease-out'
      this.element.style.opacity = '1'

      if (this.hasBackdropTarget) {
        this.backdropTarget.style.transition = 'opacity 0.3s ease-out'
        this.backdropTarget.style.opacity = '1'
      }

      if (this.hasContentTarget) {
        this.contentTarget.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out'
        this.contentTarget.style.opacity = '1'
        this.contentTarget.style.transform = 'scale(1)'
      }
    })
  }

  close() {
    if (this.prefersReducedMotion()) {
      this.element.classList.add('hidden')
      return
    }

    // Animate out
    this.element.style.opacity = '0'

    if (this.hasContentTarget) {
      this.contentTarget.style.opacity = '0'
      this.contentTarget.style.transform = 'scale(0.95)'
    }

    // Hide after animation completes
    setTimeout(() => {
      this.element.classList.add('hidden')
    }, 300)
  }

  prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
  }
}
