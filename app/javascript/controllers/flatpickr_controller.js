import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
// import { French } from "flatpickr/dist/l10n/fr" // Uncomment if you need French locale

export default class extends Controller {
  static values = { mode: String }

  connect() {
    console.log('Flatpickr controller connecting...', this.element);
    console.log('Mode value:', this.modeValue);
    console.log('Flatpickr import:', flatpickr);
    
    const options = {
      mode: this.modeValue || "single", // "single", "multiple", or "range"
      // locale: French, // Uncomment if you need French locale
      altInput: true,
      altFormat: "F j, Y",
      dateFormat: "Y-m-d",
    }

    if (this.modeValue === "range") {
      options.onChange = (selectedDates, dateStr, instance) => {
        if (selectedDates.length === 2) {
          const startDate = selectedDates[0];
          const endDate = selectedDates[1];
          // Find the form and update hidden fields
          const form = this.element.closest('form');
          if (form) {
            const startDateField = form.querySelector('input[name="date_proposal[start_date]"]');
            const endDateField = form.querySelector('input[name="date_proposal[end_date]"]');
            if (startDateField) startDateField.value = flatpickr.formatDate(startDate, "Y-m-d");
            if (endDateField) endDateField.value = flatpickr.formatDate(endDate, "Y-m-d");
            
            console.log('Flatpickr updated:', {
              start: flatpickr.formatDate(startDate, "Y-m-d"),
              end: flatpickr.formatDate(endDate, "Y-m-d"),
              startField: !!startDateField,
              endField: !!endDateField
            });
          }
        }
      };
    }

    this.flatpickr = flatpickr(this.element, options)
    console.log('Flatpickr instance created:', this.flatpickr);
  }

  disconnect() {
    console.log('Flatpickr controller disconnecting...');
    if (this.flatpickr) {
      this.flatpickr.destroy();
    }
  }
}