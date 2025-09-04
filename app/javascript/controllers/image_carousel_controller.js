import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "counter", "thumbnail"]
  static values = { total: Number }

  connect() {
    this.currentIndex = 0
    this.updateDisplay()
  }

  nextImage() {
    this.currentIndex = (this.currentIndex + 1) % this.totalValue
    this.updateDisplay()
  }

  previousImage() {
    this.currentIndex = this.currentIndex > 0 ? this.currentIndex - 1 : this.totalValue - 1
    this.updateDisplay()
  }

  goToImage(event) {
    const index = parseInt(event.params.index)
    this.currentIndex = index
    this.updateDisplay()
  }

  updateDisplay() {
    // Update carousel position
    const translateX = -this.currentIndex * 100
    this.containerTarget.style.transform = `translateX(${translateX}%)`
    
    // Update counter
    this.counterTarget.textContent = this.currentIndex + 1
    
    // Update thumbnail selection
    this.thumbnailTargets.forEach((thumb, index) => {
      if (index === this.currentIndex) {
        thumb.classList.add('border-blue-500')
        thumb.classList.remove('border-transparent')
      } else {
        thumb.classList.remove('border-blue-500')
        thumb.classList.add('border-transparent')
      }
    })
  }
}