import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editSection", "editToggle", "selectionButton", "selectionToolbar", "selectionCount", "selectionField"]

  connect() {
    this.editMode = false
    this.render()
  }

  toggleEditMode(event) {
    event.preventDefault()
    this.editMode = !this.editMode
    this.render()
  }

  toggleSelection(event) {
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

    if (this.hasSelectionToolbarTarget) {
      this.selectionToolbarTarget.classList.toggle("hidden", selectedIds.length === 0)
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
