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
    console.log('Calendar controller connecting...')
    console.log('Values:', {
      tripId: this.tripIdValue,
      currentUserId: this.currentUserIdValue,
      eventsUrl: this.eventsUrlValue,
      voteUrl: this.voteUrlValue,
      availabilityUrl: this.availabilityUrlValue
    })
    console.log('Calendar target:', this.calendarTarget)
    this.initializeCalendar()
  }

  disconnect() {
    if (this.calendar) {
      this.calendar.destroy()
    }
  }

  initializeCalendar() {
    console.log('Initializing calendar...')
    console.log('Calendar target element:', this.calendarTarget)
    console.log('FullCalendar Calendar class:', Calendar)
    
    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,timeGridWeek'
      },
      initialView: 'dayGridMonth',
      selectable: true,
      selectMirror: true,
      editable: false,
      height: 'auto',
      
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
          console.log('Calendar events loaded:', data)
          successCallback(data)
        })
        .catch(error => {
          console.error('Failed to load calendar events:', error)
          failureCallback(error)
        })
      },
      
      // Event callbacks
      select: this.handleDateSelect.bind(this),
      eventClick: this.handleEventClick.bind(this),
      
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

    console.log('About to render calendar...')
    this.calendar.render()
    console.log('Calendar rendered successfully!')
  }

  handleDateSelect(selectInfo) {
    // Open modal to create new proposal or availability
    console.log('Date range selected:', selectInfo.start, selectInfo.end)
    this.showProposalModal(selectInfo.start, selectInfo.end)
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
    if (endInput) endInput.value = this.formatDate(new Date(endDate.getTime() - 86400000)) // Subtract 1 day for end date
    
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