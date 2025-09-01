import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import interactionPlugin from "@fullcalendar/interaction"

export default class extends Controller {
  static targets = [
    "calendar", 
    "proposalModal", 
    "voteModal", 
    "availabilityModal",
    "deleteProposalContainer",
    "deleteAvailabilityContainer",
    "availabilityModalTitle",
    "availabilityId",
    "availabilityStartDate",
    "availabilityEndDate",
    "availabilityType",
    "availabilityTitle",
    "availabilityDescription",
    "availabilitySubmitButton"
  ]
  static values = { 
    tripId: String,
    currentUserId: String,
    eventsUrl: String,
    voteUrl: String,
    availabilityUrl: String
  }

  connect() {
    this.selectedDate = null
    this.initializeCalendar()
    this.boundHandlePopState = this.handlePopState.bind(this)
    this.activeModal = null
  }

  disconnect() {
    if (this.calendar) {
      this.calendar.destroy()
    }
  }

  initializeCalendar() {
    const isMobile = window.innerWidth < 768
    
    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
      headerToolbar: {
        left: 'prev,next',
        center: 'title',
        right: isMobile ? 'today' : 'today dayGridMonth'
      },
      initialView: 'dayGridMonth',
      selectable: true,
      selectMirror: true,
      editable: false,
      height: 'auto',
      aspectRatio: isMobile ? 1.0 : 1.35,
      dayMaxEventRows: isMobile ? 2 : 4,
      moreLinkClick: 'popover',
      
      events: (info, successCallback, failureCallback) => {
        fetch(this.eventsUrlValue, {
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
            'X-CSRF-Token': this.getCSRFToken()
          },
          credentials: 'same-origin'
        })
        .then(response => {
          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`)
          }
          return response.json()
        })
        .then(data => {
          successCallback(data)
        })
        .catch(error => {
          failureCallback(error)
        })
      },
      
      select: this.handleDateSelect.bind(this),
      eventClick: this.handleEventClick.bind(this),
      dateClick: this.handleDateClick.bind(this),
      
      eventContent: this.renderEvent.bind(this),
      
      eventClassNames: (arg) => {
        const event = arg.event
        const eventType = event.extendedProps.type
        
        switch(eventType) {
          case 'proposal':
            return ['proposal-event']
          case 'unavailable':
            return ['unavailable-event']
          case 'preferred':
            return ['preferred-event']
          case 'busy':
            return ['busy-event']
          default:
            return ['default-event']
        }
      }
    })

    this.calendar.render()
    
    this.addOutsideClickHandler()
  }

  handleDateSelect(selectInfo) {
    const startDate = selectInfo.start
    const endDate = new Date(selectInfo.end.getTime() - 86400000)
    this.showProposalModal(startDate, endDate)
    this.calendar.unselect()
  }

  handleDateClick(dateClickInfo) {
    const clickedDate = new Date(dateClickInfo.dateStr + 'T00:00:00Z');

    if (this.selectedDate) {
      if (this.selectedDate.getTime() === clickedDate.getTime()) {
        this.showProposalModal(clickedDate, clickedDate)
      } else {
        const startDate = this.selectedDate < clickedDate ? this.selectedDate : clickedDate
        const endDate = this.selectedDate < clickedDate ? clickedDate : this.selectedDate
        this.showProposalModal(startDate, endDate)
      }
      
      this.clearDateSelection()
      this.selectedDate = null
    } else {
      this.selectedDate = clickedDate
      this.showDateSelection(clickedDate)
    }
  }

  showDateSelection(date) {
    this.clearDateSelection()
    const dateCell = this.calendarTarget.querySelector(`[data-date="${this.formatDate(date)}"]`)
    if (dateCell) {
      dateCell.classList.add('bg-primary-accent', 'text-white')
    }
  }

  clearDateSelection() {
    const selectedCells = this.calendarTarget.querySelectorAll('.bg-primary-accent')
    selectedCells.forEach(cell => {
      cell.classList.remove('bg-primary-accent', 'text-white')
    })
  }

  addOutsideClickHandler() {
    document.addEventListener('click', (e) => {
      if (this.selectedDate && !this.element.contains(e.target)) {
        this.clearDateSelection()
        this.selectedDate = null
      }
    })
  }

  handleEventClick(clickInfo) {
    const event = clickInfo.event
    const eventType = event.extendedProps.type
    
    if (eventType === 'proposal') {
      this.showVoteModal(event)
    } else if (['unavailable', 'preferred', 'busy'].includes(eventType)) {
      this.showAvailabilityModal(event)
    }
  }

  renderEvent(arg) {
    const event = arg.event
    const eventType = event.extendedProps.type
    const votes = event.extendedProps.votes || {}
    
    if (eventType === 'proposal') {
      const voteCount = (votes.yes || 0) + (votes.no || 0) + (votes.maybe || 0)
      const userVote = event.extendedProps.userVote
      
      return {
        html: `
          <div class="fc-event-proposal">
            <div class="fc-event-title">${event.title}</div>
            <div class="fc-event-votes">
              <span class="vote-count">👥 ${voteCount}</span>
              ${userVote ? `<span class="user-vote">${this.getVoteIcon(userVote)}</span>` : ''}
            </div>
          </div>
        `
      }
    } else if (['unavailable', 'preferred', 'busy'].includes(eventType)) {
      return {
        html: `
          <div class="fc-event-availability">
            <div class="fc-event-title">${this.getAvailabilityIcon(eventType)} ${event.title}</div>
          </div>
        `
      }
    }
    
    return { html: event.title }
  }

  getVoteIcon(voteType) {
    switch(voteType) {
      case 'yes': return '✅'
      case 'no': return '❌'
      case 'maybe': return '❓'
      default: return ''
    }
  }

  getAvailabilityIcon(availabilityType) {
    switch(availabilityType) {
      case 'unavailable': return '🚫'
      case 'busy': return '📅'
      case 'preferred': return '⭐'
      default: return '📅'
    }
  }

  showProposalModal(startDate, endDate) {
    const modalElement = this.proposalModalTarget
    const startInput = modalElement.querySelector('[name="date_proposal[start_date]"]')
    const endInput = modalElement.querySelector('[name="date_proposal[end_date]"]')
    const titleInput = modalElement.querySelector('[name="date_proposal[title]"]')
    const descriptionInput = modalElement.querySelector('[name="date_proposal[description]"]')
    const idInput = modalElement.querySelector('[name="date_proposal[id]"]')
    const form = modalElement.querySelector('form')
    const submitButton = modalElement.querySelector('input[type="submit"]')
    
    if (startInput) startInput.value = this.formatDate(startDate)
    if (endInput) endInput.value = this.formatDate(endDate)
    if (titleInput) titleInput.value = ''
    if (descriptionInput) descriptionInput.value = ''
    if (idInput) idInput.value = ''
    
    // Reset form to create new proposal
    if (form) {
      form.action = `/trips/${this.tripIdValue}/date_proposals`
      delete form.dataset.editingProposalId
    }
    if (submitButton) submitButton.value = 'Propose These Dates'
    
    this.openModal(modalElement)
  }

  showVoteModal(event) {
    const modalElement = this.voteModalTarget
    const proposalId = event.extendedProps.proposalId
    const votes = event.extendedProps.votes || {}
    const userVote = event.extendedProps.userVote
    const deletable = event.extendedProps.deletable
    

    
    modalElement.querySelector('.proposal-title').textContent = event.title
    modalElement.querySelector('.proposal-id').value = proposalId
    
    modalElement.querySelector('.yes-count').textContent = votes.yes || 0
    modalElement.querySelector('.no-count').textContent = votes.no || 0
    modalElement.querySelector('.maybe-count').textContent = votes.maybe || 0
    
    const voteButtons = modalElement.querySelectorAll('.vote-button')
    voteButtons.forEach(button => {
      button.classList.remove('selected')
      if (button.dataset.vote === userVote) {
        button.classList.add('selected')
      }
    })

    if (deletable) {
      this.deleteProposalContainerTarget.style.display = 'block'
    } else {
      this.deleteProposalContainerTarget.style.display = 'none'
    }
    
    this.openModal(modalElement)
  }

  showAvailabilityModal(event) {
    const modalElement = this.availabilityModalTarget
    const { availabilityId, deletable, description, type, title } = event.extendedProps
    const startDate = event.start
    
    // FullCalendar sends end date as exclusive (one day after actual end)
    const endDate = new Date(event.end)
    endDate.setDate(endDate.getDate() - 1)
    const formattedEndDate = this.formatDate(endDate)

    this.availabilityModalTitleTarget.textContent = 'Edit Availability Period'
    this.availabilitySubmitButtonTarget.textContent = 'Update Availability'
    this.availabilityIdTarget.value = availabilityId
    this.availabilityStartDateTarget.value = startDate
    this.availabilityEndDateTarget.value = formattedEndDate
    this.availabilityTypeTarget.value = type
    this.availabilityTitleTarget.value = title || ''
    this.availabilityDescriptionTarget.value = description || ''

    if (deletable) {
      this.deleteAvailabilityContainerTarget.style.display = 'block'
    } else {
      this.deleteAvailabilityContainerTarget.style.display = 'none'
    }

    this.openModal(modalElement)
  }

  openModal(modalElement) {
    this.activeModal = modalElement
    this.activeModal.classList.remove('hidden')
    document.body.classList.add('modal-open')

    history.pushState({ modalOpen: true }, '', '#modal')
    window.addEventListener('popstate', this.boundHandlePopState)

    if (window.innerWidth < 768) {
      const firstInput = modalElement.querySelector('input, textarea, select')
      if (firstInput) {
        setTimeout(() => firstInput.focus(), 100)
      }
    }
  }

  closeModal(event) {
    history.back()
  }

  closeModalProgrammatically() {
    if (this.activeModal) {
      this.activeModal.classList.add('hidden')
      document.body.classList.remove('modal-open')
      this.activeModal = null
    }
    window.removeEventListener('popstate', this.boundHandlePopState)
  }

  handlePopState(event) {
    if (this.activeModal) {
      this.activeModal.classList.add('hidden')
      document.body.classList.remove('modal-open')
      this.activeModal = null
    }
    window.removeEventListener('popstate', this.boundHandlePopState)
  }

  formatDate(date) {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  openProposalModal() {
    const modalElement = this.proposalModalTarget
    const startInput = modalElement.querySelector('[name="date_proposal[start_date]"]')
    const endInput = modalElement.querySelector('[name="date_proposal[end_date]"]')
    const titleInput = modalElement.querySelector('[name="date_proposal[title]"]')
    const descriptionInput = modalElement.querySelector('[name="date_proposal[description]"]')
    const idInput = modalElement.querySelector('[name="date_proposal[id]"]')
    const form = modalElement.querySelector('form')
    const submitButton = modalElement.querySelector('input[type="submit"]')
    
    if (startInput) startInput.value = ''
    if (endInput) endInput.value = ''
    if (titleInput) titleInput.value = ''
    if (descriptionInput) descriptionInput.value = ''
    if (idInput) idInput.value = ''
    
    // Reset form to create new proposal
    if (form) {
      form.action = `/trips/${this.tripIdValue}/date_proposals`
      delete form.dataset.editingProposalId
    }
    if (submitButton) submitButton.value = 'Propose These Dates'
    
    this.openModal(this.proposalModalTarget)
  }

  openAvailabilityModal() {
    const modalElement = this.availabilityModalTarget
    this.availabilityModalTitleTarget.textContent = 'Add Availability Period'
    this.availabilitySubmitButtonTarget.textContent = 'Add Availability'
    this.availabilityIdTarget.value = ''
    modalElement.querySelector('form').reset()
    this.deleteAvailabilityContainerTarget.style.display = 'none'
    this.openModal(modalElement)
  }

  vote(event) {
    const voteType = event.currentTarget.dataset.vote
    const proposalId = this.voteModalTarget.querySelector('.proposal-id').value
    
    const voteButtons = this.voteModalTarget.querySelectorAll('.vote-button')
    voteButtons.forEach(button => button.classList.remove('selected'))
    event.currentTarget.classList.add('selected')
    
    this.submitVoteAsync(proposalId, voteType)
  }

  async submitVoteAsync(proposalId, voteType) {
    const formData = new FormData()
    formData.append('date_proposal_vote[date_proposal_id]', proposalId)
    formData.append('date_proposal_vote[vote_type]', voteType)
    
    try {
      const response = await fetch(this.voteUrlValue, {
        method: 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (response.ok) {
        this.calendar.refetchEvents()
        this.showToast('Vote recorded!', 'success')
      } else {
        this.showToast('Error recording vote. Please try again.', 'error')
      }
    } catch (error) {
      console.error('Voting error:', error)
      this.showToast('Error recording vote. Please try again.', 'error')
    }
  }

  async submitProposal(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)
    let proposalId = formData.get('date_proposal[id]')
    let method = 'POST'

    // Fallback to data attribute if hidden field is empty
    if (!proposalId && form.dataset.editingProposalId) {
      proposalId = form.dataset.editingProposalId
    }

    // Always construct the URL dynamically
    let url
    if (proposalId) {
      method = 'PATCH'
      url = `/trips/${this.tripIdValue}/date_proposals/${proposalId}`
    } else {
      url = `/trips/${this.tripIdValue}/date_proposals`
    }

    try {
      const response = await fetch(url, {
        method: method,
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (response.ok) {
        this.calendar.refetchEvents()
        this.closeModalProgrammatically()
        form.reset()
        // Reset form action to create new proposals only if we were creating a new proposal
        if (!proposalId) {
          form.action = `/trips/${this.tripIdValue}/date_proposals`
          const submitButton = form.querySelector('input[type="submit"]')
          if (submitButton) submitButton.value = 'Propose These Dates'
        }
        
        // Clear the editing proposal ID
        delete form.dataset.editingProposalId
        
        // Show success toast
        const message = proposalId ? 'Date proposal updated!' : 'Date proposal added!'
        this.showToast(message, 'success')
      } else {
        const error = await response.json()
        const errorMessage = error.errors ? Object.values(error.errors).join(', ') : 'Unknown error'
        this.showToast('Error: ' + errorMessage, 'error')
      }
    } catch (error) {
      this.showToast('An unexpected error occurred. Please try again.', 'error')
    }
  }

  async submitAvailability(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)
    const availabilityId = this.availabilityIdTarget.value
    let url = this.availabilityUrlValue
    let method = 'POST'

    if (availabilityId) {
      url = `${this.availabilityUrlValue}/${availabilityId}`
      method = 'PATCH'
    }

    try {
      const response = await fetch(url, {
        method: method,
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
              if (response.ok) {
          this.calendar.refetchEvents()
          this.closeModalProgrammatically()
          form.reset()
          
          // Show success toast
          const message = availabilityId ? 'Availability updated!' : 'Availability added!'
          this.showToast(message, 'success')
        } else {
          const error = await response.json()
          const errorMessage = error.errors ? Object.values(error.errors).join(', ') : 'Unknown error'
          this.showToast('Error: ' + errorMessage, 'error')
        }
      } catch (error) {
        this.showToast('An unexpected error occurred. Please try again.', 'error')
      }
  }

  editProposal() {
    const proposalId = this.voteModalTarget.querySelector('.proposal-id').value
    if (!proposalId) return

    // Find the proposal event in the calendar
    const proposalEvent = this.calendar.getEventById(`proposal_${proposalId}`)
    if (!proposalEvent) {
      alert('Proposal not found')
      return
    }
    

    
    // Populate the proposal modal with the event data
    const modalElement = this.proposalModalTarget
    const startInput = modalElement.querySelector('[name="date_proposal[start_date]"]')
    const endInput = modalElement.querySelector('[name="date_proposal[end_date]"]')
    const titleInput = modalElement.querySelector('[name="date_proposal[title]"]')
    const descriptionInput = modalElement.querySelector('[name="date_proposal[description]"]')
    const idInput = modalElement.querySelector('[name="date_proposal[id]"]')
    
    if (startInput) startInput.value = proposalEvent.start
    if (endInput) {
      // FullCalendar sends end date as exclusive (one day after actual end)
      // We need to subtract one day to get the actual end date
      const endDate = new Date(proposalEvent.end)
      endDate.setDate(endDate.getDate() - 1)
      endInput.value = this.formatDate(endDate)
    }
    if (titleInput) titleInput.value = proposalEvent.extendedProps.title || ''
    if (descriptionInput) descriptionInput.value = proposalEvent.extendedProps.description || ''
    if (idInput) {
      idInput.value = proposalId
    }
    
    // Store the proposal ID in a data attribute on the form
    const form = modalElement.querySelector('form')
    if (form) {
      form.dataset.editingProposalId = proposalId
    }
    
    // Change the submit button text
    const submitButton = modalElement.querySelector('input[type="submit"]')
    if (submitButton) submitButton.value = 'Update Proposal'
    
    // Close the vote modal and open the proposal modal
    this.closeModalProgrammatically()
    setTimeout(() => {
      this.openModal(modalElement)
    }, 100)
  }

  async deleteProposal() {
    const proposalId = this.voteModalTarget.querySelector('.proposal-id').value
    if (!proposalId) return

    if (confirm('Are you sure you want to delete this proposal?')) {
      try {
        const response = await fetch(`/trips/${this.tripIdValue}/date_proposals/${proposalId}`, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': this.getCSRFToken(),
            'Accept': 'application/json'
          }
        })

        if (response.ok) {
          this.calendar.refetchEvents()
          this.closeModalProgrammatically()
          this.showToast('Date proposal deleted!', 'success')
        } else {
          const error = await response.json()
          this.showToast(`Error deleting proposal: ${error.error}`, 'error')
        }
      } catch (error) {
        this.showToast('An unexpected error occurred. Please try again.', 'error')
      }
    }
  }

  async deleteAvailability() {
    const availabilityId = this.availabilityIdTarget.value
    if (!availabilityId) return

    if (confirm('Are you sure you want to delete this availability?')) {
      try {
        const response = await fetch(`/trips/${this.tripIdValue}/user_availabilities/${availabilityId}`, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': this.getCSRFToken(),
            'Accept': 'application/json'
          }
        })

        if (response.ok) {
          this.calendar.refetchEvents()
          this.closeModalProgrammatically()
          this.showToast('Availability deleted!', 'success')
        } else {
          const error = await response.json()
          this.showToast(`Error deleting availability: ${error.error}`, 'error')
        }
      } catch (error) {
        this.showToast('An unexpected error occurred. Please try again.', 'error')
      }
    }
  }

  showToast(message, type = 'success') {
    const toast = document.getElementById('toast')
    const toastMessage = document.getElementById('toast-message')
    const toastIcon = document.getElementById('toast-icon')
    
    if (!toast || !toastMessage || !toastIcon) return
    
    // Set message
    toastMessage.textContent = message
    
    // Set icon and colors based on type
    if (type === 'success') {
      toastIcon.innerHTML = '<svg class="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>'
      toast.className = 'bg-green-50 border-green-200 rounded-lg shadow-lg px-4 py-3 max-w-sm mx-4 pointer-events-auto'
    } else if (type === 'error') {
      toastIcon.innerHTML = '<svg class="w-5 h-5 text-red-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"></path></svg>'
      toast.className = 'bg-red-50 border-red-200 rounded-lg shadow-lg px-4 py-3 max-w-sm mx-4 pointer-events-auto'
    } else {
      toastIcon.innerHTML = '<svg class="w-5 h-5 text-blue-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>'
      toast.className = 'bg-blue-50 border-blue-200 rounded-lg shadow-lg px-4 py-3 max-w-sm mx-4 pointer-events-auto'
    }
    
    // Show toast with animation
    toast.classList.remove('hidden')
    toast.style.transform = 'translateY(-100%)'
    toast.style.opacity = '0'
    
    // Animate in
    setTimeout(() => {
      toast.style.transition = 'all 0.3s ease-out'
      toast.style.transform = 'translateY(0)'
      toast.style.opacity = '1'
    }, 10)
    
    // Auto-hide after 3 seconds
    setTimeout(() => {
      toast.style.transform = 'translateY(-100%)'
      toast.style.opacity = '0'
      setTimeout(() => {
        toast.classList.add('hidden')
      }, 300)
    }, 3000)
  }

  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]')
    return metaTag ? metaTag.getAttribute('content') : ''
  }
}