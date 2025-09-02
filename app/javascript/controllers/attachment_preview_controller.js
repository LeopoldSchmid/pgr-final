import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  previewFile(event) {
    event.preventDefault()
    
    const fileUrl = event.currentTarget.dataset.fileUrl
    const fileName = event.currentTarget.dataset.fileName
    const fileType = event.currentTarget.dataset.fileType
    const downloadUrl = event.currentTarget.dataset.downloadUrl
    
    const modal = document.getElementById('attachment-modal')
    const modalContent = document.getElementById('attachment-modal-content')
    const modalTitle = document.getElementById('attachment-modal-title')
    const downloadLink = document.getElementById('attachment-download-link')
    
    modalTitle.textContent = fileName
    downloadLink.href = downloadUrl
    
    // Clear previous content
    modalContent.innerHTML = ''
    
    if (fileType.startsWith('image/')) {
      // Show image
      const img = document.createElement('img')
      img.src = fileUrl
      img.alt = fileName
      img.classList.add('max-w-full', 'max-h-96', 'object-contain', 'rounded-lg', 'mx-auto')
      modalContent.appendChild(img)
      
    } else if (fileType === 'application/pdf') {
      // Show PDF embed
      const embed = document.createElement('embed')
      embed.src = fileUrl
      embed.type = 'application/pdf'
      embed.classList.add('w-full', 'h-96', 'rounded-lg')
      modalContent.appendChild(embed)
      
    } else if (fileType === 'text/plain' || fileType === 'text/csv') {
      // Show text content
      fetch(fileUrl)
        .then(response => response.text())
        .then(text => {
          const pre = document.createElement('pre')
          pre.textContent = text.substring(0, 2000) // Limit to first 2000 characters
          pre.classList.add('bg-gray-100', 'p-4', 'rounded-lg', 'text-sm', 'overflow-auto', 'max-h-96', 'whitespace-pre-wrap')
          
          if (text.length > 2000) {
            const truncated = document.createElement('div')
            truncated.textContent = '... (truncated, download to see full content)'
            truncated.classList.add('text-gray-500', 'text-xs', 'mt-2', 'italic')
            modalContent.appendChild(pre)
            modalContent.appendChild(truncated)
          } else {
            modalContent.appendChild(pre)
          }
        })
        .catch(error => {
          this.showFileInfo(fileName, fileType, modalContent)
        })
      
    } else {
      // Show file info for other file types
      this.showFileInfo(fileName, fileType, modalContent)
    }
    
    // Show modal
    modal.classList.remove('hidden')
    modal.classList.add('flex')
    document.body.style.overflow = 'hidden'
  }

  showFileInfo(fileName, fileType, container) {
    const fileInfo = document.createElement('div')
    fileInfo.classList.add('text-center', 'py-8')
    
    let icon = '📄'
    if (fileType.includes('word')) icon = '📝'
    else if (fileType.includes('excel') || fileType.includes('sheet')) icon = '📊'
    else if (fileType.includes('pdf')) icon = '📋'
    
    fileInfo.innerHTML = `
      <div class="text-6xl mb-4">${icon}</div>
      <div class="text-xl font-semibold mb-2">${fileName}</div>
      <div class="text-gray-600 mb-4">
        ${fileType || 'Unknown file type'}
      </div>
      <div class="text-sm text-gray-500">
        This file type cannot be previewed in the browser.<br>
        Click the download button above to view the file.
      </div>
    `
    container.appendChild(fileInfo)
  }

  closeModal() {
    const modal = document.getElementById('attachment-modal')
    modal.classList.add('hidden')
    modal.classList.remove('flex')
    document.body.style.overflow = 'auto'
  }

  connect() {
    // Close on escape key
    this.boundKeyHandler = this.handleKeyPress.bind(this)
    document.addEventListener('keydown', this.boundKeyHandler)
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundKeyHandler)
  }

  handleKeyPress(event) {
    if (event.key === 'Escape') {
      this.closeModal()
    }
  }
}