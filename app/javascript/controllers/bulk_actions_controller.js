import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "deleteButton", "exportButton"]

  connect() {
    this.updateButtonVisibility()
  }

  toggleAll(event) {
    const isChecked = event.target.checked
    this.checkboxes.forEach(checkbox => {
      checkbox.checked = isChecked
    })
    this.updateButtonVisibility()
  }

  toggleEntry() {
    this.updateButtonVisibility()
  }

  deleteSelected() {
    if (confirm("Are you sure you want to delete the selected journal entries? This action cannot be undone.")) {
      this.formTarget.submit()
    }
  }

  exportSelected() {
    const selectedIds = this.selectedCheckboxes.map(checkbox => checkbox.value)
    if (selectedIds.length > 0) {
      // Construct the URL for bulk export
      // Assuming a route like /trips/:trip_id/journal_entries/bulk_export
      const tripId = this.data.get("tripId") // Need to pass trip_id from HTML
      const url = `/trips/${tripId}/journal_entries/bulk_export?ids=${selectedIds.join(',')}`
      window.location.href = url
    } else {
      alert("Please select at least one journal entry to export.")
    }
  }

  updateButtonVisibility() {
    if (this.selectedCheckboxes.length > 0) {
      this.deleteButtonTarget.classList.remove("hidden")
      this.exportButtonTarget.classList.remove("hidden")
    } else {
      this.deleteButtonTarget.classList.add("hidden")
      this.exportButtonTarget.classList.add("hidden")
    }
  }

  get checkboxes() {
    return Array.from(this.formTarget.querySelectorAll("input[type=checkbox][name='journal_entry_ids[]']"))
  }

  get selectedCheckboxes() {
    return this.checkboxes.filter(checkbox => checkbox.checked)
  }
}