import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-animation"
// Adds smooth animations to form inputs on focus/blur and error states
export default class extends Controller {
  static targets = ["input", "error"]

  connect() {
    // Add focus/blur animations to all inputs
    if (this.hasInputTarget) {
      this.inputTargets.forEach(input => {
        this.setupInputAnimations(input)
      })
    }
  }

  setupInputAnimations(input) {
    if (this.prefersReducedMotion()) return

    // Add focus animation
    input.addEventListener('focus', () => {
      input.style.transition = 'transform 0.2s ease-out, box-shadow 0.2s ease-out'
      input.style.transform = 'translateY(-1px)'
    })

    // Add blur animation
    input.addEventListener('blur', () => {
      input.style.transform = 'translateY(0)'
    })
  }

  // Call this method when showing an error
  showError(event) {
    if (this.prefersReducedMotion()) return

    const errorElement = event.target

    // Shake animation for the input
    const input = errorElement.closest('.field')?.querySelector('input, textarea, select')
    if (input) {
      input.classList.add('animate-shake')
      setTimeout(() => {
        input.classList.remove('animate-shake')
      }, 500)
    }

    // Slide in error message
    if (this.hasErrorTarget) {
      this.errorTargets.forEach(error => {
        if (!error.classList.contains('hidden')) {
          error.style.opacity = '0'
          error.style.transform = 'translateY(-5px)'

          requestAnimationFrame(() => {
            error.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out'
            error.style.opacity = '1'
            error.style.transform = 'translateY(0)'
          })
        }
      })
    }
  }

  // Call this method when hiding an error
  hideError(event) {
    if (this.prefersReducedMotion()) return

    const errorElement = event.target
    errorElement.style.opacity = '0'
    errorElement.style.transform = 'translateY(-5px)'
  }

  // Add loading state to submit button
  showLoading(event) {
    if (this.prefersReducedMotion()) return

    const button = event.target
    button.disabled = true
    button.style.opacity = '0.7'
    button.style.cursor = 'not-allowed'

    // Add spinner if not already present
    if (!button.querySelector('.spinner')) {
      const spinner = document.createElement('span')
      spinner.className = 'spinner inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin ml-2'
      button.appendChild(spinner)
    }
  }

  hideLoading(event) {
    const button = event.target
    button.disabled = false
    button.style.opacity = '1'
    button.style.cursor = 'pointer'

    const spinner = button.querySelector('.spinner')
    if (spinner) {
      spinner.remove()
    }
  }

  prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches
  }
}
