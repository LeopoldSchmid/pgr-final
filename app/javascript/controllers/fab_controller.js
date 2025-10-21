import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button", "menuItem"]

  connect() {
    // Add entrance animation to the FAB button on load
    if (!this.prefersReducedMotion() && this.hasButtonTarget) {
      this.buttonTarget.style.opacity = '0'
      this.buttonTarget.style.transform = 'scale(0.8)'

      requestAnimationFrame(() => {
        this.buttonTarget.style.transition = 'opacity 0.4s ease-out, transform 0.4s ease-out'
        this.buttonTarget.style.opacity = '1'
        this.buttonTarget.style.transform = 'scale(1)'
      })
    }

    this.isOpen = false
  }

  toggleMenu() {
    this.isOpen = !this.isOpen

    if (this.isOpen) {
      this.openMenu()
    } else {
      this.closeMenu()
    }
  }

  openMenu() {
    if (!this.hasMenuTarget) return

    // Show menu
    this.menuTarget.classList.remove("hidden")

    // Rotate the button icon
    if (this.hasButtonTarget && !this.prefersReducedMotion()) {
      this.buttonTarget.style.transform = 'rotate(45deg)'
    }

    // Animate menu items in with stagger
    if (this.hasMenuItemTarget && !this.prefersReducedMotion()) {
      this.menuItemTargets.forEach((item, index) => {
        item.style.opacity = '0'
        item.style.transform = 'scale(0.8) translateY(10px)'

        setTimeout(() => {
          item.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out'
          item.style.opacity = '1'
          item.style.transform = 'scale(1) translateY(0)'
        }, index * 50) // Stagger by 50ms
      })
    }
  }

  closeMenu() {
    if (!this.hasMenuTarget) return

    // Rotate button back
    if (this.hasButtonTarget && !this.prefersReducedMotion()) {
      this.buttonTarget.style.transform = 'rotate(0deg)'
    }

    // Animate menu items out
    if (this.hasMenuItemTarget && !this.prefersReducedMotion()) {
      this.menuItemTargets.forEach((item, index) => {
        setTimeout(() => {
          item.style.opacity = '0'
          item.style.transform = 'scale(0.8) translateY(10px)'
        }, index * 30)
      })

      // Hide menu after animations complete
      setTimeout(() => {
        this.menuTarget.classList.add("hidden")
      }, this.menuItemTargets.length * 30 + 300)
    } else {
      this.menuTarget.classList.add("hidden")
    }
  }

  prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
  }
}
