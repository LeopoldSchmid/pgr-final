import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editSection", "editToggle", "selectionButton", "selectionToolbar", "selectionCount", "selectionField", "mainFab", "fabMenu"]

  connect() {
    this.editMode = false
    this.fabOpen = false
    this.loadSelectionFromSession()
    this.render()
  }

  loadSelectionFromSession() {
    const saved = sessionStorage.getItem("shopping_plan_selected")
    if (saved) {
      const ids = saved.split(",").filter(Boolean)
      this.selectionButtonTargets.forEach((button) => {
        if (ids.includes(button.dataset.requirementId)) {
          button.checked = true
        }
      })
    }
  }

  saveSelectionToSession() {
    const selectedIds = []
    this.selectionButtonTargets.forEach((button) => {
      if (button.checked) selectedIds.push(button.dataset.requirementId)
    })
    sessionStorage.setItem("shopping_plan_selected", selectedIds.join(","))
  }

  toggleEditMode(event) {
    event.preventDefault()
    this.editMode = !this.editMode
    this.render()
  }

  toggleSelection(event) {
    this.saveSelectionToSession()
    this.render()
  }

  toggleFabMenu(event) {
    event?.preventDefault()
    this.fabOpen = !this.fabOpen
    this.saveSelectionToSession()
    this.render()
  }

  render() {
    this.editSectionTargets.forEach((section) => {
      section.classList.toggle("hidden", !this.editMode)
    })

    if (this.hasEditToggleTarget) {
      this.editToggleTarget.textContent = this.editMode ? "Done" : "Edit"
    }

    const selectedIds = []
    this.selectionButtonTargets.forEach((button) => {
      const selected = button.checked
      if (selected) selectedIds.push(button.dataset.requirementId)
    })

    const hasSelection = selectedIds.length > 0

    if (this.hasSelectionToolbarTarget) {
      this.selectionToolbarTarget.classList.toggle("hidden", !hasSelection)
    }

    if (this.hasMainFabTarget) {
      this.mainFabTarget.classList.toggle("hidden", !hasSelection)
      this.mainFabTarget.classList.toggle("flex", hasSelection)
    }

    if (this.hasFabMenuTarget) {
      this.fabMenuTarget.classList.toggle("hidden", !hasSelection || !this.fabOpen)
      this.fabMenuTarget.classList.toggle("flex", hasSelection && this.fabOpen)
    }

    if (this.hasSelectionCountTarget) {
      this.selectionCountTarget.textContent = String(selectedIds.length)
    }

    if (this.hasSelectionFieldTarget) {
      this.selectionFieldTarget.value = selectedIds.join(",")
    }

    this.selectionButtonTargets.forEach((button) => {
      this.renderSelection(button, button.checked)
    })
  }

  renderSelection(button, selected) {
    const visual = button.parentElement?.querySelector("[data-selection-visual]")
    const icon = button.parentElement?.querySelector("[data-selection-icon]")

    if (visual) {
      visual.classList.toggle("border-slate-300", !selected)
      visual.classList.toggle("bg-white", !selected)
      visual.classList.toggle("border-primary-accent", selected)
      visual.classList.toggle("bg-primary-accent/10", selected)
    }

    if (icon) {
      icon.classList.toggle("opacity-0", !selected)
      icon.classList.toggle("opacity-100", selected)
    }
  }
}
