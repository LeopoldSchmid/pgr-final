import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "previewContainer", "uploadButton", "uploadText"]

  connect() {
    this.hidePreview()
  }

  preview(event) {
    // Clear existing previews
    this.previewContainerTarget.innerHTML = ''

    const files = event.target.files

    if (files.length > 0) {
      if (files.length === 1) {
        // Single image - show normally
        this.showSingleImage(files[0])
      } else {
        // Multiple images - show carousel
        this.showImageCarousel(Array.from(files))
      }
      this.showPreview()
    } else {
      this.hidePreview()
    }
  }

  showSingleImage(file) {
    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = document.createElement('img')
        img.src = e.target.result
        img.classList.add('max-w-full', 'h-64', 'object-cover', 'rounded-lg', 'shadow-md', 'mx-auto')
        this.previewContainerTarget.appendChild(img)
      }
      reader.readAsDataURL(file)
    }
  }

  showImageCarousel(files) {
    // Create carousel container
    const carouselContainer = document.createElement('div')
    carouselContainer.classList.add('relative', 'bg-gray-50', 'rounded-lg', 'overflow-hidden')
    
    // Create header with counter and change button
    const header = document.createElement('div')
    header.classList.add('flex', 'items-center', 'justify-between', 'mb-2')
    
    const counter = document.createElement('div')
    counter.classList.add('text-sm', 'text-gray-600', 'font-medium')
    counter.textContent = `${files.length} photos selected`
    
    const changeButton = document.createElement('button')
    changeButton.type = 'button'
    changeButton.textContent = 'Change Photos'
    changeButton.classList.add('text-xs', 'text-primary-accent', 'hover:underline')
    changeButton.addEventListener('click', (e) => {
      e.preventDefault()
      this.inputTarget.click()
    })
    
    header.appendChild(counter)
    header.appendChild(changeButton)
    carouselContainer.appendChild(header)

    // Main display area
    const mainArea = document.createElement('div')
    mainArea.classList.add('relative', 'h-64', 'bg-white', 'rounded-lg', 'mb-3', 'overflow-hidden')
    
    const mainDisplay = document.createElement('div')
    mainDisplay.classList.add('w-full', 'h-full', 'flex', 'items-center', 'justify-center')
    mainDisplay.dataset.currentIndex = '0'
    
    // Navigation arrows
    if (files.length > 1) {
      const prevButton = document.createElement('button')
      prevButton.type = 'button'
      prevButton.innerHTML = '‹'
      prevButton.classList.add('absolute', 'left-2', 'top-1/2', 'transform', '-translate-y-1/2', 'bg-black', 'bg-opacity-50', 'text-white', 'rounded-full', 'w-8', 'h-8', 'flex', 'items-center', 'justify-center', 'text-xl', 'font-bold', 'hover:bg-opacity-75', 'z-10')
      prevButton.addEventListener('click', (e) => {
        e.preventDefault()
        this.previousPreviewImage(mainDisplay, files)
      })
      
      const nextButton = document.createElement('button')
      nextButton.type = 'button'
      nextButton.innerHTML = '›'
      nextButton.classList.add('absolute', 'right-2', 'top-1/2', 'transform', '-translate-y-1/2', 'bg-black', 'bg-opacity-50', 'text-white', 'rounded-full', 'w-8', 'h-8', 'flex', 'items-center', 'justify-center', 'text-xl', 'font-bold', 'hover:bg-opacity-75', 'z-10')
      nextButton.addEventListener('click', (e) => {
        e.preventDefault()
        this.nextPreviewImage(mainDisplay, files)
      })
      
      mainArea.appendChild(prevButton)
      mainArea.appendChild(nextButton)
    }
    
    mainArea.appendChild(mainDisplay)
    carouselContainer.appendChild(mainArea)
    
    // Thumbnail strip for multiple images
    if (files.length > 1) {
      const thumbStrip = document.createElement('div')
      thumbStrip.classList.add('flex', 'gap-2', 'justify-center', 'overflow-x-auto', 'pb-2')
      
      files.forEach((file, index) => {
        if (file.type.startsWith('image/')) {
          const thumbContainer = document.createElement('div')
          thumbContainer.classList.add('flex-shrink-0', 'cursor-pointer', 'rounded', 'overflow-hidden', 'border-2')
          thumbContainer.classList.add(index === 0 ? 'border-blue-500' : 'border-transparent')
          thumbContainer.dataset.index = index
          
          thumbContainer.addEventListener('click', (e) => {
            e.preventDefault()
            this.showPreviewImageAtIndex(mainDisplay, files, index)
            this.updatePreviewThumbnailSelection(thumbStrip, index)
          })
          
          const reader = new FileReader()
          reader.onload = (e) => {
            const img = document.createElement('img')
            img.src = e.target.result
            img.classList.add('w-12', 'h-12', 'object-cover')
            thumbContainer.appendChild(img)
          }
          reader.readAsDataURL(file)
          
          thumbStrip.appendChild(thumbContainer)
        }
      })
      
      carouselContainer.appendChild(thumbStrip)
    }
    
    this.previewContainerTarget.appendChild(carouselContainer)
    
    // Show first image
    this.showPreviewImageAtIndex(mainDisplay, files, 0)
  }

  showPreviewImageAtIndex(mainDisplay, files, index) {
    mainDisplay.innerHTML = ''
    mainDisplay.dataset.currentIndex = index
    
    const file = files[index]
    
    // Add image counter
    if (files.length > 1) {
      const counter = document.createElement('div')
      counter.classList.add('absolute', 'top-2', 'right-2', 'bg-black', 'bg-opacity-50', 'text-white', 'px-2', 'py-1', 'rounded', 'text-xs')
      counter.textContent = `${index + 1}/${files.length}`
      mainDisplay.appendChild(counter)
    }
    
    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = document.createElement('img')
        img.src = e.target.result
        img.classList.add('max-w-full', 'max-h-full', 'object-contain', 'rounded-lg')
        mainDisplay.appendChild(img)
      }
      reader.readAsDataURL(file)
    }
  }

  updatePreviewThumbnailSelection(thumbStrip, activeIndex) {
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

  previousPreviewImage(mainDisplay, files) {
    const currentIndex = parseInt(mainDisplay.dataset.currentIndex)
    const newIndex = currentIndex > 0 ? currentIndex - 1 : files.length - 1
    this.showPreviewImageAtIndex(mainDisplay, files, newIndex)
    
    const thumbStrip = mainDisplay.parentElement.parentElement.querySelector('.flex.gap-2')
    if (thumbStrip) {
      this.updatePreviewThumbnailSelection(thumbStrip, newIndex)
    }
  }

  nextPreviewImage(mainDisplay, files) {
    const currentIndex = parseInt(mainDisplay.dataset.currentIndex)
    const newIndex = currentIndex < files.length - 1 ? currentIndex + 1 : 0
    this.showPreviewImageAtIndex(mainDisplay, files, newIndex)
    
    const thumbStrip = mainDisplay.parentElement.parentElement.querySelector('.flex.gap-2')
    if (thumbStrip) {
      this.updatePreviewThumbnailSelection(thumbStrip, newIndex)
    }
  }

  showPreview() {
    this.previewContainerTarget.classList.remove('hidden')
    // Hide the upload UI when preview is shown
    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.classList.add('hidden')
    }
    if (this.hasUploadTextTarget) {
      this.uploadTextTarget.classList.add('hidden')
    }
  }

  hidePreview() {
    this.previewContainerTarget.classList.add('hidden')
    this.previewContainerTarget.innerHTML = '' // Clear images when hidden
    // Show the upload UI when preview is hidden
    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.classList.remove('hidden')
    }
    if (this.hasUploadTextTarget) {
      this.uploadTextTarget.classList.remove('hidden')
    }
  }

  removeImage(event) {
    event.preventDefault()
    this.inputTarget.value = '' // Clear the file input
    this.hidePreview()
  }
}