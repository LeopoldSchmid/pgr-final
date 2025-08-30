import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "container"]

  connect() {
    this.hidePreview()
  }

  preview(event) {
    const file = event.target.files[0]
    
    if (file && file.type.startsWith('image/')) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        this.previewTarget.src = e.target.result
        this.showPreview()
      }
      
      reader.readAsDataURL(file)
    } else if (file) {
      // Non-image file selected
      this.hidePreview()
    } else {
      // No file selected (cleared)
      this.hidePreview()
    }
  }

  showPreview() {
    this.containerTarget.classList.remove('hidden')
    this.previewTarget.classList.remove('hidden')
  }

  hidePreview() {
    this.containerTarget.classList.add('hidden')
    this.previewTarget.classList.add('hidden')
  }

  removeImage(event) {
    event.preventDefault()
    this.inputTarget.value = ''
    this.hidePreview()
  }
}