import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameInput", "fileInput", "previewContainer", "removeButton"]

  connect() {
    this.hidePreview()
  }

  fileSelected(event) {
    const file = event.target.files[0]
    
    if (file) {
      // Auto-populate filename without extension
      const fileName = file.name.replace(/\.[^/.]+$/, "")
      this.nameInputTarget.value = fileName
      
      // Show preview for supported file types
      this.showFilePreview(file)
    } else {
      this.hidePreview()
    }
  }

  showFilePreview(file) {
    this.previewContainerTarget.innerHTML = ''

    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = document.createElement('img')
        img.src = e.target.result
        img.classList.add('max-w-full', 'h-32', 'object-cover', 'rounded-lg', 'shadow-md', 'mb-2')
        this.previewContainerTarget.appendChild(img)
      }
      reader.readAsDataURL(file)
      this.showPreview()
    } else {
      // Show file info for non-image files
      const fileInfo = document.createElement('div')
      fileInfo.classList.add('bg-gray-100', 'p-3', 'rounded-lg', 'text-sm', 'text-gray-600', 'mb-2')
      fileInfo.innerHTML = `
        <div class="flex items-center">
          <span class="text-lg mr-2">📄</span>
          <div>
            <div class="font-medium">${file.name}</div>
            <div class="text-xs">${this.formatFileSize(file.size)} • ${file.type || 'Unknown type'}</div>
          </div>
        </div>
      `
      this.previewContainerTarget.appendChild(fileInfo)
      this.showPreview()
    }
  }

  showPreview() {
    this.previewContainerTarget.classList.remove('hidden')
    if (this.hasRemoveButtonTarget) {
      this.removeButtonTarget.classList.remove('hidden')
    }
  }

  hidePreview() {
    this.previewContainerTarget.classList.add('hidden')
    this.previewContainerTarget.innerHTML = ''
    if (this.hasRemoveButtonTarget) {
      this.removeButtonTarget.classList.add('hidden')
    }
  }

  removeFile(event) {
    event.preventDefault()
    this.fileInputTarget.value = ''
    this.nameInputTarget.value = ''
    this.hidePreview()
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }
}