import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  openLightbox(event) {
    event.preventDefault();
    const imageUrl = event.currentTarget.dataset.galleryImageUrl;
    const caption = event.currentTarget.dataset.galleryCaption;
    
    const modal = document.getElementById('lightbox-modal');
    const image = document.getElementById('lightbox-image');
    const captionEl = document.getElementById('lightbox-caption');
    
    image.src = imageUrl;
    captionEl.textContent = caption;
    modal.classList.remove('hidden');
    modal.classList.add('flex');
    
    document.body.style.overflow = 'hidden';
  }
  
  closeLightbox() {
    const modal = document.getElementById('lightbox-modal');
    modal.classList.add('hidden');
    modal.classList.remove('flex');
    document.body.style.overflow = 'auto';
  }
  
  connect() {
    // Close on escape key
    this.boundKeyHandler = this.handleKeyPress.bind(this);
    document.addEventListener('keydown', this.boundKeyHandler);
  }
  
  disconnect() {
    document.removeEventListener('keydown', this.boundKeyHandler);
  }
  
  handleKeyPress(event) {
    if (event.key === 'Escape') {
      this.closeLightbox();
    }
  }
}