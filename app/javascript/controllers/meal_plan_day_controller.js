import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="meal-plan-day"
export default class extends Controller {
  static targets = ["chip", "section", "scrollContainer", "card", "editOnly", "displayOnly", "editToggle", "editToggleIcon"]

  connect() {
    this.editMode = false
    this.longPressTimer = null
    this.observer = new IntersectionObserver(this.handleIntersections.bind(this), {
      root: null,
      threshold: 0.35
    })

    this.sectionTargets.forEach((section) => this.observer.observe(section))
    this.setInitialActive()
    this.renderEditMode()
  }

  disconnect() {
    this.cancelLongPress()
    this.observer?.disconnect()
  }

  handleIntersections(entries) {
    const visible = entries
      .filter((entry) => entry.isIntersecting)
      .sort((a, b) => b.intersectionRatio - a.intersectionRatio)

    if (visible.length === 0) return

    const section = visible[0].target
    const type = section.dataset.mealPlanDayTypeParam
    this.activate(type)
  }

  setInitialActive() {
    const first = this.sectionTargets[0]
    if (!first) return

    this.activate(first.dataset.mealPlanDayTypeParam)
  }

  activate(type) {
    this.chipTargets.forEach((chip) => {
      const selected = chip.dataset.mealPlanDayTypeParam === type
      chip.classList.toggle("bg-primary-accent", selected)
      chip.classList.toggle("text-white", selected)
      chip.classList.toggle("text-slate-500", !selected)
      chip.classList.toggle("shadow-sm", selected)
    })
  }

  startLongPress(event) {
    this.cancelLongPress()

    const chip = event.currentTarget
    const formId = chip.dataset.mealPlanDayOpenFormIdParam
    if (!formId) return

    this.longPressTimer = window.setTimeout(() => {
      this.openAddForm(formId)
    }, 450)
  }

  cancelLongPress() {
    if (!this.longPressTimer) return

    window.clearTimeout(this.longPressTimer)
    this.longPressTimer = null
  }

  openAddForm(formId) {
    const form = document.getElementById(formId)
    if (!form) return

    form.setAttribute("open", "open")
    form.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  toggleEditMode(event) {
    event?.preventDefault()
    this.editMode = !this.editMode
    this.renderEditMode()
  }

  renderEditMode() {
    this.editOnlyTargets.forEach((target) => {
      target.classList.toggle("hidden", !this.editMode)
    })

    this.displayOnlyTargets.forEach((target) => {
      target.classList.toggle("hidden", this.editMode)
    })

    this.cardTargets.forEach((card) => {
      card.classList.toggle("bg-slate-50/60", this.editMode)
      card.classList.toggle("border-primary-accent/30", this.editMode)
    })

    if (this.hasEditToggleTarget) {
      this.editToggleTarget.classList.toggle("bg-primary-accent", this.editMode)
      this.editToggleTarget.classList.toggle("text-white", this.editMode)
      this.editToggleTarget.classList.toggle("text-slate-600", !this.editMode)
      this.editToggleTarget.setAttribute("aria-pressed", this.editMode ? "true" : "false")
      this.editToggleTarget.setAttribute("title", this.editMode ? "Close edit mode" : "Open edit mode")
    }

    if (this.hasEditToggleIconTarget) {
      if (this.editMode) {
        this.editToggleIconTarget.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />'
      } else {
        this.editToggleIconTarget.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536M9 11l6.232-6.232a2.5 2.5 0 113.536 3.536L12.536 14.536A4 4 0 0110.5 15.5H7v-3.5A4 4 0 018.464 9.464L15 3" />'
      }
    }
  }
}
