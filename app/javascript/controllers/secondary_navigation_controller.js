import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="secondary-navigation"
export default class extends Controller {
  static targets = ["item"]

  connect() {
    // Ensure active item is visible on load (scroll into view if needed)
    this.scrollToActive()
  }

  scrollToActive() {
    const activeItem = this.itemTargets.find(item =>
      item.classList.contains('text-primary-accent')
    )

    if (activeItem) {
      activeItem.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
        inline: 'center'
      })
    }
  }
}
