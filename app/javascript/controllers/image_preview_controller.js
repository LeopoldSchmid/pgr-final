import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "previewContainer"]

  connect() {
    this.hidePreview()
  }

  preview(event) {
    // Clear existing previews
    this.previewContainerTarget.innerHTML = ''

    const files = event.target.files

    if (files.length > 0) {
      Array.from(files).forEach(file => {
        if (file.type.startsWith('image/')) {
          const reader = new FileReader()
          reader.onload = (e) => {
            const img = document.createElement('img')
            img.src = e.target.result
            img.classList.add('max-w-full', 'h-48', 'object-cover', 'rounded-lg', 'shadow-md', 'mb-2') // Added mb-2 for spacing
            this.previewContainerTarget.appendChild(img)
          }
          reader.readAsDataURL(file)
        }
      })
      this.showPreview()
    } else {
      this.hidePreview()
    }
  }

  showPreview() {
    this.previewContainerTarget.classList.remove('hidden')
  }

  hidePreview() {
    this.previewContainerTarget.classList.add('hidden')
    this.previewContainerTarget.innerHTML = '' // Clear images when hidden
  }

  removeImage(event) {
    event.preventDefault()
    this.inputTarget.value = '' // Clear the file input
    this.hidePreview()
  }
}