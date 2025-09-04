import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameInput", "fileInput", "previewContainer", "removeButton", "uploadButton"]

  connect() {
    console.log("=== Multi-attachment form controller connected ===")
    this.selectedFiles = []
    this.hidePreview()
  }

  filesSelected(event) {
    console.log("=== Files selected ===", event.target.files)
    const files = Array.from(event.target.files)
    
    if (files.length > 0) {
      this.selectedFiles = files
      
      // Auto-populate name from first file if name is empty
      if (this.nameInputTarget.value.trim() === '' && files[0]) {
        const fileName = files[0].name.replace(/\.[^/.]+$/, "")
        this.nameInputTarget.value = fileName
      }
      
      // Show preview carousel for all files
      this.showFilePreviews(files)
    } else {
      this.selectedFiles = []
      this.hidePreview()
    }
  }

  showFilePreviews(files) {
    this.previewContainerTarget.innerHTML = ''

    if (files.length === 0) {
      this.hidePreview()
      return
    }

    // Create carousel container
    const carouselContainer = document.createElement('div')
    carouselContainer.classList.add('relative', 'bg-gray-50', 'rounded-lg', 'p-4')
    
    // Create file counter
    const counter = document.createElement('div')
    counter.classList.add('text-sm', 'text-gray-600', 'mb-2', 'text-center')
    counter.textContent = `${files.length} file${files.length > 1 ? 's' : ''} selected`
    carouselContainer.appendChild(counter)

    if (files.length === 1) {
      // Single file - show normally
      this.showSingleFilePreview(files[0], carouselContainer)
    } else {
      // Multiple files - show carousel
      this.showCarouselPreview(files, carouselContainer)
    }

    this.previewContainerTarget.appendChild(carouselContainer)
    this.showPreview()
  }

  showSingleFilePreview(file, container) {
    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = document.createElement('img')
        img.src = e.target.result
        img.classList.add('max-w-full', 'h-32', 'object-cover', 'rounded-lg', 'shadow-md', 'mx-auto')
        container.appendChild(img)
      }
      reader.readAsDataURL(file)
    } else {
      this.showFileInfo(file, container)
    }
  }

  showCarouselPreview(files, container) {
    // Create main carousel area
    const mainArea = document.createElement('div')
    mainArea.classList.add('relative', 'mb-3')
    
    // Create main image display
    const mainDisplay = document.createElement('div')
    mainDisplay.classList.add('flex', 'justify-center', 'items-center', 'h-32', 'bg-white', 'rounded-lg', 'shadow-sm')
    mainDisplay.dataset.currentIndex = '0'
    
    // Create navigation arrows
    const prevButton = document.createElement('button')
    prevButton.type = 'button'
    prevButton.innerHTML = '‹'
    prevButton.classList.add('absolute', 'left-2', 'top-1/2', 'transform', '-translate-y-1/2', 'bg-black', 'bg-opacity-50', 'text-white', 'rounded-full', 'w-8', 'h-8', 'flex', 'items-center', 'justify-center', 'text-xl', 'font-bold', 'hover:bg-opacity-75', 'z-10')
    prevButton.addEventListener('click', (e) => {
      e.preventDefault()
      this.previousImage(mainDisplay, files)
    })
    
    const nextButton = document.createElement('button')
    nextButton.type = 'button'
    nextButton.innerHTML = '›'
    nextButton.classList.add('absolute', 'right-2', 'top-1/2', 'transform', '-translate-y-1/2', 'bg-black', 'bg-opacity-50', 'text-white', 'rounded-full', 'w-8', 'h-8', 'flex', 'items-center', 'justify-center', 'text-xl', 'font-bold', 'hover:bg-opacity-75', 'z-10')
    nextButton.addEventListener('click', (e) => {
      e.preventDefault()
      this.nextImage(mainDisplay, files)
    })
    
    mainArea.appendChild(mainDisplay)
    mainArea.appendChild(prevButton)
    mainArea.appendChild(nextButton)
    container.appendChild(mainArea)
    
    // Create thumbnail strip
    const thumbStrip = document.createElement('div')
    thumbStrip.classList.add('flex', 'gap-2', 'justify-center', 'overflow-x-auto', 'pb-2')
    
    files.forEach((file, index) => {
      const thumbContainer = document.createElement('div')
      thumbContainer.classList.add('flex-shrink-0', 'cursor-pointer', 'rounded', 'overflow-hidden', 'border-2', 'border-transparent')
      thumbContainer.dataset.index = index
      
      if (index === 0) {
        thumbContainer.classList.add('border-blue-500')
      }
      
      thumbContainer.addEventListener('click', (e) => {
        e.preventDefault()
        this.showImageAtIndex(mainDisplay, files, index)
        this.updateThumbnailSelection(thumbStrip, index)
      })
      
      if (file.type.startsWith('image/')) {
        const reader = new FileReader()
        reader.onload = (e) => {
          const img = document.createElement('img')
          img.src = e.target.result
          img.classList.add('w-12', 'h-12', 'object-cover')
          thumbContainer.appendChild(img)
        }
        reader.readAsDataURL(file)
      } else {
        const fileIcon = document.createElement('div')
        fileIcon.classList.add('w-12', 'h-12', 'bg-gray-200', 'flex', 'items-center', 'justify-center', 'text-xs')
        fileIcon.textContent = '📄'
        thumbContainer.appendChild(fileIcon)
      }
      
      thumbStrip.appendChild(thumbContainer)
    })
    
    container.appendChild(thumbStrip)
    
    // Show first image
    this.showImageAtIndex(mainDisplay, files, 0)
  }

  showImageAtIndex(mainDisplay, files, index) {
    mainDisplay.innerHTML = ''
    mainDisplay.dataset.currentIndex = index
    
    const file = files[index]
    
    // Add image counter
    const counter = document.createElement('div')
    counter.classList.add('absolute', 'top-2', 'right-2', 'bg-black', 'bg-opacity-50', 'text-white', 'px-2', 'py-1', 'rounded', 'text-xs')
    counter.textContent = `${index + 1}/${files.length}`
    mainDisplay.appendChild(counter)
    
    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = document.createElement('img')
        img.src = e.target.result
        img.classList.add('max-w-full', 'max-h-full', 'object-contain', 'rounded-lg')
        mainDisplay.appendChild(img)
      }
      reader.readAsDataURL(file)
    } else {
      this.showFileInfo(file, mainDisplay)
    }
  }

  updateThumbnailSelection(thumbStrip, activeIndex) {
    thumbStrip.querySelectorAll('[data-index]').forEach((thumb, index) => {
      if (index === activeIndex) {
        thumb.classList.add('border-blue-500')
        thumb.classList.remove('border-transparent')
      } else {
        thumb.classList.remove('border-blue-500')
        thumb.classList.add('border-transparent')
      }
    })
  }

  previousImage(mainDisplay, files) {
    const currentIndex = parseInt(mainDisplay.dataset.currentIndex)
    const newIndex = currentIndex > 0 ? currentIndex - 1 : files.length - 1
    this.showImageAtIndex(mainDisplay, files, newIndex)
    
    const thumbStrip = mainDisplay.parentElement.parentElement.querySelector('.flex.gap-2')
    this.updateThumbnailSelection(thumbStrip, newIndex)
  }

  nextImage(mainDisplay, files) {
    const currentIndex = parseInt(mainDisplay.dataset.currentIndex)
    const newIndex = currentIndex < files.length - 1 ? currentIndex + 1 : 0
    this.showImageAtIndex(mainDisplay, files, newIndex)
    
    const thumbStrip = mainDisplay.parentElement.parentElement.querySelector('.flex.gap-2')
    this.updateThumbnailSelection(thumbStrip, newIndex)
  }

  showFileInfo(file, container) {
    const fileInfo = document.createElement('div')
    fileInfo.classList.add('bg-gray-100', 'p-3', 'rounded-lg', 'text-sm', 'text-gray-600', 'text-center')
    
    let icon = '📄'
    if (file.type.includes('word')) icon = '📝'
    else if (file.type.includes('excel') || file.type.includes('sheet')) icon = '📊'
    else if (file.type.includes('pdf')) icon = '📋'
    
    fileInfo.innerHTML = `
      <div class="text-2xl mb-2">${icon}</div>
      <div class="font-medium">${file.name}</div>
      <div class="text-xs mt-1">${this.formatFileSize(file.size)} • ${file.type || 'Unknown type'}</div>
    `
    container.appendChild(fileInfo)
  }

  showPreview() {
    this.previewContainerTarget.classList.remove('hidden')
    if (this.hasRemoveButtonTarget) {
      this.removeButtonTarget.classList.remove('hidden')
    }
    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.textContent = `Upload ${this.selectedFiles.length} file${this.selectedFiles.length > 1 ? 's' : ''}`
    }
  }

  hidePreview() {
    this.previewContainerTarget.classList.add('hidden')
    this.previewContainerTarget.innerHTML = ''
    if (this.hasRemoveButtonTarget) {
      this.removeButtonTarget.classList.add('hidden')
    }
    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.textContent = 'Upload'
    }
  }

  removeFiles(event) {
    event.preventDefault()
    this.fileInputTarget.value = ''
    this.nameInputTarget.value = ''
    this.selectedFiles = []
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