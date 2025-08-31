import { Controller } from "@hotwired/stimulus"
import { Calendar } from "@fullcalendar/core"
import dayGridPlugin from "@fullcalendar/daygrid"
import timeGridPlugin from "@fullcalendar/timegrid"
import interactionPlugin from "@fullcalendar/interaction"

export default class extends Controller {
  static targets = ["calendar", "proposalModal", "voteModal", "availabilityModal"]
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
      
      // Event sources
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
      
      // Event callbacks
      select: this.handleDateSelect.bind(this),
      eventClick: this.handleEventClick.bind(this),
      dateClick: this.handleDateClick.bind(this),
      
      // Event rendering
      eventContent: this.renderEvent.bind(this),
      
      // Color coding for different event types
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
    
    // Add mobile touch event handling after render
    if (window.innerWidth < 768) {
      this.addMobileTouchHandling()
    }
    
    // Add click outside to cancel selection
    this.addOutsideClickHandler()
  }

  handleDateSelect(selectInfo) {
    // Handle drag selection (date range)
    const startDate = selectInfo.start
    const endDate = new Date(selectInfo.end.getTime() - 86400000) // Subtract 1 day for inclusive end date
    this.showProposalModal(startDate, endDate)
    this.calendar.unselect() // Clear the selection
  }

  handleDateClick(dateClickInfo) {
    // Handle date clicks - same logic as mobile for consistency
    const clickedDate = dateClickInfo.date
    
    if (this.selectedDate) {
      // Second click - check if same date or different
      if (this.selectedDate.getTime() === clickedDate.getTime()) {
        // Second click on same date - create single day proposal
        this.showProposalModal(clickedDate, clickedDate)
      } else {
        // Second click on different date - create date range proposal
        const startDate = this.selectedDate < clickedDate ? this.selectedDate : clickedDate
        const endDate = this.selectedDate < clickedDate ? clickedDate : this.selectedDate
        this.showProposalModal(startDate, endDate)
      }
      
      // Clear selection
      if (window.innerWidth < 768) {
        this.clearMobileSelection()
      }
      this.selectedDate = null
    } else {
      // First click - select the date
      this.selectedDate = clickedDate
      if (window.innerWidth < 768) {
        this.showMobileSelection(clickedDate)
      }
    }
  }

  addMobileTouchHandling() {
    // Add direct touch event listeners for better mobile responsiveness
    const calendarElement = this.calendarTarget
    
    calendarElement.addEventListener('touchstart', (e) => {
      this.touchStartTime = Date.now()
    }, { passive: true })
    
    calendarElement.addEventListener('touchend', (e) => {
      // Only handle if it's a quick tap (not a long press or drag)
      if (Date.now() - this.touchStartTime < 200) {
        const touch = e.changedTouches[0]
        const element = document.elementFromPoint(touch.clientX, touch.clientY)
        
        // Find the date cell that was tapped
        const dateCell = element.closest('.fc-daygrid-day')
        if (dateCell && dateCell.getAttribute('data-date')) {
          const dateStr = dateCell.getAttribute('data-date')
          const tappedDate = new Date(dateStr + 'T12:00:00') // Add time to avoid timezone issues
          
          this.handleMobileDateTap(tappedDate)
        }
      }
    }, { passive: true })
  }

  handleMobileDateTap(tappedDate) {
    if (this.selectedDate) {
      // Second tap - check if same date or different
      if (this.selectedDate.getTime() === tappedDate.getTime()) {
        // Second tap on same date - create single day proposal
        this.showProposalModal(tappedDate, tappedDate)
      } else {
        // Second tap on different date - create date range proposal
        const startDate = this.selectedDate < tappedDate ? this.selectedDate : tappedDate
        const endDate = this.selectedDate < tappedDate ? tappedDate : this.selectedDate
        this.showProposalModal(startDate, endDate)
      }
      
      // Clear selection and visual feedback
      this.clearMobileSelection()
      this.selectedDate = null
    } else {
      // First tap - select and highlight the date
      this.selectedDate = tappedDate
      this.showMobileSelection(tappedDate)
    }
  }

  showMobileSelection(date) {
    // Clear any previous selection
    this.clearMobileSelection()
    
    // Highlight the selected date
    const dateCell = this.calendarTarget.querySelector(`[data-date="${this.formatDate(date)}"]`)
    if (dateCell) {
      dateCell.style.backgroundColor = '#1976d2'
      dateCell.style.color = 'white'
      dateCell.classList.add('mobile-selected')
    }
  }

  clearMobileSelection() {
    // Remove highlights from all selected dates
    const selectedCells = this.calendarTarget.querySelectorAll('.mobile-selected')
    selectedCells.forEach(cell => {
      cell.style.backgroundColor = ''
      cell.style.color = ''
      cell.classList.remove('mobile-selected')
    })
  }

  addOutsideClickHandler() {
    // Allow users to cancel selection by clicking/tapping outside the calendar
    document.addEventListener('click', (e) => {
      if (this.selectedDate && !this.element.contains(e.target)) {
        this.selectedDate = null
        if (window.innerWidth < 768) {
          this.clearMobileSelection()
        }
      }
    })
  }

  handleEventClick(clickInfo) {
    const event = clickInfo.event
    const eventType = event.extendedProps.type
    
    console.log('Event clicked:', event.title, eventType)
    
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
    // Set modal form dates
    const modalElement = this.proposalModalTarget
    const startInput = modalElement.querySelector('[name="date_proposal[start_date]"]')
    const endInput = modalElement.querySelector('[name="date_proposal[end_date]"]')
    
    if (startInput) startInput.value = this.formatDate(startDate)
    if (endInput) endInput.value = this.formatDate(endDate)
    
    // Clear description field for new proposal
    const descriptionInput = modalElement.querySelector('[name="date_proposal[description]"]')
    if (descriptionInput) descriptionInput.value = ''
    
    this.openModal(modalElement)
  }

  showVoteModal(event) {
    const modalElement = this.voteModalTarget
    const proposalId = event.id
    const votes = event.extendedProps.votes || {}
    const userVote = event.extendedProps.userVote
    
    // Update modal content
    modalElement.querySelector('.proposal-title').textContent = event.title
    modalElement.querySelector('.proposal-id').value = proposalId
    
    // Update vote counts
    modalElement.querySelector('.yes-count').textContent = votes.yes || 0
    modalElement.querySelector('.no-count').textContent = votes.no || 0
    modalElement.querySelector('.maybe-count').textContent = votes.maybe || 0
    
    // Highlight user's current vote
    const voteButtons = modalElement.querySelectorAll('.vote-button')
    voteButtons.forEach(button => {
      button.classList.remove('selected')
      if (button.dataset.vote === userVote) {
        button.classList.add('selected')
      }
    })
    
    this.openModal(modalElement)
  }

  showAvailabilityModal(event) {
    const modalElement = this.availabilityModalTarget
    // Implementation for availability editing
    this.openModal(modalElement)
  }

  openModal(modalElement) {
    modalElement.classList.remove('hidden')
    document.body.classList.add('modal-open')
    
    // On mobile, focus the first input for better UX
    if (window.innerWidth < 768) {
      const firstInput = modalElement.querySelector('input, textarea, select')
      if (firstInput) {
        setTimeout(() => firstInput.focus(), 100)
      }
    }
  }

  closeModal(event) {
    const modalElement = event.target.closest('.modal')
    modalElement.classList.add('hidden')
    document.body.classList.remove('modal-open')
  }

  async submitVote(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)
    
    try {
      const response = await fetch(this.voteUrlValue, {
        method: 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        // Refresh calendar events
        this.calendar.refetchEvents()
        this.closeModal(event)
      }
    } catch (error) {
      console.error('Voting error:', error)
    }
  }

  formatDate(date) {
    return date.toISOString().split('T')[0]
  }

  // Action methods for modal interactions
  openProposalModal() {
    this.openModal(this.proposalModalTarget)
  }

  openAvailabilityModal() {
    this.openModal(this.availabilityModalTarget)
  }

  vote(event) {
    const voteType = event.target.dataset.vote
    const proposalId = event.target.closest('.modal').querySelector('.proposal-id').value
    
    // Update UI immediately for responsiveness
    const voteButtons = event.target.closest('.vote-buttons').querySelectorAll('.vote-button')
    voteButtons.forEach(button => button.classList.remove('selected'))
    event.target.classList.add('selected')
    
    // Submit vote
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
      }
    } catch (error) {
      console.error('Voting error:', error)
    }
  }

  async submitAvailability(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)
    
    try {
      const response = await fetch(this.availabilityUrlValue, {
        method: 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (response.ok) {
        // Refresh calendar events
        this.calendar.refetchEvents()
        this.closeModal(event)
        
        // Reset form
        form.reset()
      } else {
        const error = await response.json()
        console.error('Availability submission error:', error)
        alert('Error adding availability: ' + (error.errors ? Object.values(error.errors).join(', ') : 'Unknown error'))
      }
    } catch (error) {
      console.error('Availability submission error:', error)
      alert('Error adding availability. Please try again.')
    }
  }

  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]')
    return metaTag ? metaTag.getAttribute('content') : ''
  }
}