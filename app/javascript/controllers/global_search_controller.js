import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="global-search"
export default class extends Controller {
  static targets = ["input", "results", "backdrop", "container", "resultsList"]
  static values = {
    url: String,
    debounceDelay: { type: Number, default: 300 }
  }

  connect() {
    this.debounceTimer = null
    this.selectedIndex = -1
    this.abortController = null

    // Listen for keyboard shortcut (Cmd/Ctrl+K)
    document.addEventListener('keydown', this.handleGlobalKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleGlobalKeydown.bind(this))
    if (this.abortController) {
      this.abortController.abort()
    }
  }

  handleGlobalKeydown(event) {
    // Check for Cmd+K (Mac) or Ctrl+K (Windows/Linux)
    if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
      event.preventDefault()
      this.open()
    }

    // Close on Escape
    if (event.key === 'Escape' && !this.resultsTarget.classList.contains('hidden')) {
      event.preventDefault()
      this.close()
    }
  }

  open() {
    // Show the search interface
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove('hidden')
    }
    this.containerTarget.classList.remove('hidden')
    this.resultsTarget.classList.add('hidden')
    this.inputTarget.focus()
    this.inputTarget.value = ''
    this.selectedIndex = -1
  }

  close() {
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add('hidden')
    }
    this.containerTarget.classList.add('hidden')
    this.resultsTarget.classList.add('hidden')
    this.inputTarget.value = ''
    this.selectedIndex = -1
  }

  search(event) {
    const query = event.target.value.trim()

    // Clear previous timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Cancel previous request
    if (this.abortController) {
      this.abortController.abort()
    }

    // Hide results if query is empty
    if (query.length === 0) {
      this.resultsTarget.classList.add('hidden')
      return
    }

    // Debounce the search
    this.debounceTimer = setTimeout(() => {
      this.performSearch(query)
    }, this.debounceDelayValue)
  }

  async performSearch(query) {
    try {
      // Create new abort controller for this request
      this.abortController = new AbortController()

      const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
      const response = await fetch(url, {
        signal: this.abortController.signal,
        headers: {
          'Accept': 'application/json'
        }
      })

      if (!response.ok) {
        throw new Error('Search request failed')
      }

      const data = await response.json()
      this.displayResults(data)
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Search error:', error)
      }
    }
  }

  displayResults(data) {
    // Show the results container
    this.resultsTarget.classList.remove('hidden')

    // Clear previous results
    this.resultsListTarget.innerHTML = ''
    this.selectedIndex = -1

    if (data.results.length === 0) {
      this.resultsListTarget.innerHTML = `
        <div class="px-4 py-8 text-center text-text-secondary">
          <svg class="mx-auto h-12 w-12 text-text-secondary/50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <p class="mt-2 text-sm">No results found</p>
        </div>
      `
      return
    }

    // Group results by type
    const grouped = this.groupByType(data.results)

    // Render grouped results
    Object.keys(grouped).forEach(type => {
      const items = grouped[type]

      // Add section header
      const header = document.createElement('div')
      header.className = 'px-4 py-2 text-xs font-semibold text-text-secondary uppercase bg-background-primary/50 sticky top-0'
      header.textContent = this.formatTypeName(type)
      this.resultsListTarget.appendChild(header)

      // Add items
      items.forEach((item, index) => {
        const resultItem = this.createResultItem(item)
        this.resultsListTarget.appendChild(resultItem)
      })
    })
  }

  groupByType(results) {
    return results.reduce((acc, item) => {
      if (!acc[item.type]) {
        acc[item.type] = []
      }
      acc[item.type].push(item)
      return acc
    }, {})
  }

  formatTypeName(type) {
    const typeNames = {
      'trip': 'Trips',
      'journal_entry': 'Journal Entries',
      'recipe': 'Recipes',
      'discussion': 'Discussions',
      'expense': 'Expenses',
      'date_proposal': 'Date Proposals'
    }
    return typeNames[type] || type
  }

  createResultItem(item) {
    const div = document.createElement('a')
    div.href = item.url
    div.className = 'block px-4 py-3 hover:bg-primary-accent/10 cursor-pointer border-l-2 border-transparent hover:border-primary-accent transition-all duration-200'
    div.setAttribute('data-action', 'click->global-search#navigate mouseenter->global-search#highlightItem')
    div.setAttribute('data-url', item.url)

    const icon = this.getIconForType(item.type)

    div.innerHTML = `
      <div class="flex items-start gap-3">
        <div class="flex-shrink-0 mt-0.5">
          ${icon}
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2">
            <p class="text-sm font-medium text-text-primary truncate">${this.escapeHtml(item.title)}</p>
            ${item.badge ? `<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-primary-accent/20 text-primary-accent">${this.escapeHtml(item.badge)}</span>` : ''}
          </div>
          ${item.subtitle ? `<p class="text-xs text-text-secondary truncate mt-0.5">${this.escapeHtml(item.subtitle)}</p>` : ''}
          ${item.description ? `<p class="text-xs text-text-secondary line-clamp-2 mt-1">${this.escapeHtml(item.description)}</p>` : ''}
        </div>
      </div>
    `

    return div
  }

  getIconForType(type) {
    const icons = {
      'trip': `<svg class="w-5 h-5 text-primary-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`,
      'journal_entry': `<svg class="w-5 h-5 text-accent-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
      </svg>`,
      'recipe': `<svg class="w-5 h-5 text-accent-yellow" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
      </svg>`,
      'discussion': `<svg class="w-5 h-5 text-accent-purple" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
      </svg>`,
      'expense': `<svg class="w-5 h-5 text-accent-red" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>`,
      'date_proposal': `<svg class="w-5 h-5 text-accent-teal" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
      </svg>`
    }
    return icons[type] || icons['trip']
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  handleKeydown(event) {
    const items = this.resultsListTarget.querySelectorAll('a')

    if (items.length === 0) return

    switch(event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.updateSelection(items)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.updateSelection(items)
        break
      case 'Enter':
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()
        }
        break
    }
  }

  updateSelection(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-primary-accent/10', 'border-primary-accent')
        item.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
      } else {
        item.classList.remove('bg-primary-accent/10', 'border-primary-accent')
      }
    })
  }

  highlightItem(event) {
    const items = Array.from(this.resultsListTarget.querySelectorAll('a'))
    this.selectedIndex = items.indexOf(event.currentTarget)
    this.updateSelection(items)
  }

  navigate(event) {
    // Let the link handle navigation naturally
    // The close will happen via Turbo navigation
    this.close()
  }

  clickBackdrop(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }
}
