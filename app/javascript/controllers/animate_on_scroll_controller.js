import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="animate-on-scroll"
// Usage: <div data-controller="animate-on-scroll" data-animate-on-scroll-animation-class="animate-slide-up">
export default class extends Controller {
  static values = {
    animationClass: { type: String, default: "animate-slide-up" },
    threshold: { type: Number, default: 0.1 },
    once: { type: Boolean, default: true },
    delay: { type: Number, default: 0 }
  }

  connect() {
    // Skip animations if user prefers reduced motion
    if (this.prefersReducedMotion()) {
      this.element.classList.add('opacity-100')
      return
    }

    // Initially hide the element
    this.element.style.opacity = '0'

    // Apply delay if specified (useful for staggered animations)
    if (this.delayValue > 0) {
      this.element.style.transitionDelay = `${this.delayValue}ms`
    }

    // Set up Intersection Observer
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.animateIn()

          // Stop observing if this should only animate once
          if (this.onceValue) {
            this.observer.unobserve(this.element)
          }
        } else if (!this.onceValue) {
          this.animateOut()
        }
      })
    }, {
      threshold: this.thresholdValue,
      rootMargin: '0px 0px -50px 0px' // Trigger slightly before element is fully visible
    })

    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  animateIn() {
    this.element.style.opacity = '1'
    this.element.classList.add(this.animationClassValue)

    // Remove animation class after animation completes to allow re-animation if needed
    this.element.addEventListener('animationend', () => {
      if (!this.onceValue) {
        this.element.classList.remove(this.animationClassValue)
      }
    }, { once: true })
  }

  animateOut() {
    this.element.style.opacity = '0'
    this.element.classList.remove(this.animationClassValue)
  }

  prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
  }
}
