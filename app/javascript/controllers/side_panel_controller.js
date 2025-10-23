import { Controller } from "@hotwired/stimulus"

// Side Panel Controller
// Handles the avatar side panel that slides in from the left on mobile
// and appears as a dropdown from the top-right on desktop
export default class extends Controller {
  static targets = ["panel", "backdrop"]

  connect() {
    console.log("Side panel controller connected");
    // Close panel when clicking outside on mobile
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)

    // Close panel on escape key
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.boundHandleEscape)
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundHandleEscape)
  }

  toggle(event) {
    console.log("Toggling side panel");
    event.preventDefault()
    event.stopPropagation()

    const isOpen = !this.panelTarget.classList.contains('translate-x-full') &&
                   !this.panelTarget.classList.contains('md:scale-0')

    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    console.log("Opening side panel");
    // Show backdrop on mobile
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove('hidden')
      // Trigger reflow for animation
      this.backdropTarget.offsetHeight
      this.backdropTarget.classList.add('opacity-100')
    }

    // Slide in panel from right on mobile
    this.panelTarget.classList.remove('translate-x-full')

    // Scale in on desktop
    this.panelTarget.classList.remove('md:scale-0')
    this.panelTarget.classList.add('md:scale-100')

    // Add click listener to close on outside click
    setTimeout(() => {
      document.addEventListener('click', this.boundHandleClickOutside)
    }, 100)
  }

  close() {
    console.log("Closing side panel");
    // Hide backdrop on mobile
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove('opacity-100')
      setTimeout(() => {
        this.backdropTarget.classList.add('hidden')
      }, 300)
    }

    // Slide out panel on mobile
    this.panelTarget.classList.add('translate-x-full')

    // Scale out on desktop
    this.panelTarget.classList.remove('md:scale-100')
    this.panelTarget.classList.add('md:scale-0')

    // Remove click listener
    document.removeEventListener('click', this.boundHandleClickOutside)
  }

  handleClickOutside(event) {
    if (event.target.closest('[data-side-panel-element]')) {
      return
    }

    this.close()
  }

  handleEscape(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
}
