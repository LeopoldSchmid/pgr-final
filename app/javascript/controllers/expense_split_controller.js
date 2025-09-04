import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["equalSplit", "customSplit", "totalAssigned", "remaining", "validationError", "receiptPreview", "receiptImage"]
  static values = { page: String }

  // Handle form submission to ensure proper data is sent
  submitExpenseSplitForm(event) {
    const form = event.target
    const splitType = document.querySelector('input[name="split_type"]:checked')?.value
    
    if (splitType === 'equal') {
      // In equal mode, disable all custom amount inputs to prevent them from being submitted
      const customInputs = document.querySelectorAll('input[name*="custom_amounts"]')
      customInputs.forEach(input => {
        input.disabled = true
        input.value = "0.00"
      })
    } else {
      // In custom mode, disable participant checkboxes to prevent conflicts
      const participantCheckboxes = document.querySelectorAll('input[name="expense[participant_ids][]"]')
      participantCheckboxes.forEach(checkbox => {
        checkbox.disabled = true
        checkbox.checked = false
      })
    }
  }

  connect() {
    // Initialize with small delay to ensure DOM is ready
    setTimeout(() => {
      if (this.pageValue === "new") {
        this.initializeDefaultSelections()
      }
      this.initializeCustomSplit()
      this.calculateRemaining()
      this.updateEqualAmounts()
    }, 100)
  }

  initializeDefaultSelections() {
    // Ensure all equal split participants are checked by default
    const equalCheckboxes = document.querySelectorAll('input[name="expense[participant_ids][]"]')
    equalCheckboxes.forEach(checkbox => {
      if (!checkbox.hasAttribute('checked')) {
        checkbox.checked = true
      }
    })
    
    // Ensure all custom split participants are checked by default
    const customCheckboxes = document.querySelectorAll('input[data-expense-split-target*="customParticipant"]')
    customCheckboxes.forEach(checkbox => {
      if (!checkbox.hasAttribute('checked')) {
        checkbox.checked = true
      }
    })
  }

  initializeCustomSplit() {
    // Set initial state of custom amount inputs based on checkboxes
    const customCheckboxes = document.querySelectorAll('input[data-expense-split-target*="customParticipant"]')
    customCheckboxes.forEach(checkbox => {
      const memberId = checkbox.dataset.memberId
      const input = document.querySelector(`input[name="expense[custom_amounts][${memberId}]"]`)
      
      if (input) {
        input.disabled = !checkbox.checked
        if (!checkbox.checked) {
          input.classList.add('opacity-50')
          input.value = "0.00"
        } else {
          input.classList.remove('opacity-50')
        }
      }
    })
  }

  toggleSplitType(event) {
    const splitType = event.target.value
    
    if (splitType === "equal") {
      this.equalSplitTarget.classList.remove("hidden")
      this.customSplitTarget.classList.add("hidden")
      
      // Clear custom amounts when switching to equal split and disable them
      const customInputs = this.customSplitTarget.querySelectorAll('input[type="number"]')
      customInputs.forEach(input => {
        input.value = "0.00"
        input.disabled = true
      })
      
      this.updateEqualAmounts()
    } else {
      this.equalSplitTarget.classList.add("hidden")
      this.customSplitTarget.classList.remove("hidden")
      
      // Uncheck all equal split checkboxes when switching to custom
      const checkboxes = this.equalSplitTarget.querySelectorAll('input[type="checkbox"]')
      checkboxes.forEach(checkbox => checkbox.checked = false)
      
      // Re-initialize custom split to enable/disable appropriate inputs
      this.initializeCustomSplit()
    }
    
    this.calculateRemaining()
  }

  splitEvenly() {
    // Get total amount
    const amountField = document.querySelector('input[name="expense[amount]"]')
    const totalAmount = parseFloat(amountField?.value || 0)
    
    if (totalAmount <= 0) {
      alert("Please enter a valid amount first")
      return
    }
    
    // Get only selected participants' custom amount inputs
    const selectedInputs = []
    const customCheckboxes = document.querySelectorAll('input[data-expense-split-target*="customParticipant"]:checked')
    
    customCheckboxes.forEach(checkbox => {
      const memberId = checkbox.dataset.memberId
      const input = document.querySelector(`input[name="expense[custom_amounts][${memberId}]"]`)
      if (input) {
        selectedInputs.push(input)
      }
    })
    
    const numParticipants = selectedInputs.length
    
    if (numParticipants === 0) {
      alert("Please select at least one participant")
      return
    }
    
    // Calculate equal split with remainder handling
    const amountPerPerson = (totalAmount / numParticipants)
    const roundedAmountPerPerson = Math.floor(amountPerPerson * 100) / 100
    let remainder = totalAmount - (roundedAmountPerPerson * numParticipants)
    
    // Clear all amounts first
    const allInputs = document.querySelectorAll('input[name*="custom_amounts"]')
    allInputs.forEach(input => input.value = "0.00")
    
    // Distribute amounts only to selected participants
    selectedInputs.forEach((input, index) => {
      let amount = roundedAmountPerPerson
      // Give remainder to first person
      if (index === 0) {
        amount += remainder
      }
      input.value = amount.toFixed(2)
    })
    
    this.calculateRemaining()
  }

  calculateRemaining() {
    // Get the total expense amount
    const amountField = document.querySelector('input[name="expense[amount]"]')
    const totalAmount = parseFloat(amountField?.value || 0)
    
    // Calculate total assigned in custom split - only count enabled inputs (selected participants)
    let customInputs
    if (this.hasCustomSplitTarget) {
      customInputs = this.customSplitTarget.querySelectorAll('input[type="number"]:not(:disabled)')
    } else {
      customInputs = document.querySelectorAll('input[name*="custom_amounts"]:not(:disabled)')
    }
    
    let totalAssigned = 0
    
    customInputs.forEach(input => {
      const checkbox = document.querySelector(`input[data-member-id="${input.name.match(/\[(\d+)\]$/)?.[1]}"]`)
      // Only count if checkbox is checked (or if no checkbox exists for backward compatibility)
      if (!checkbox || checkbox.checked) {
        totalAssigned += parseFloat(input.value || 0)
      }
    })
    
    const remaining = totalAmount - totalAssigned
    
    // Update display
    if (this.hasTotalAssignedTarget) {
      this.totalAssignedTarget.textContent = totalAssigned.toFixed(2)
    }
    
    if (this.hasRemainingTarget) {
      this.remainingTarget.textContent = remaining.toFixed(2)
      
      // Color coding and validation
      if (Math.abs(remaining) < 0.01) { // Allow for small floating point errors
        this.remainingTarget.classList.add("text-green-600")
        this.remainingTarget.classList.remove("text-red-600", "text-yellow-800")
        this.hideValidationError()
      } else {
        this.remainingTarget.classList.add("text-red-600")
        this.remainingTarget.classList.remove("text-green-600", "text-yellow-800")
        this.showValidationError()
      }
    }
    
    // Enable/disable submit button based on validation
    this.updateSubmitButton()
    
    // Update equal amounts if we're in equal split mode
    if (this.hasEqualSplitTarget && !this.equalSplitTarget.classList.contains("hidden")) {
      this.updateEqualAmounts()
    }
  }
  
  showValidationError() {
    if (this.hasValidationErrorTarget) {
      this.validationErrorTarget.classList.remove("hidden")
    }
  }
  
  hideValidationError() {
    if (this.hasValidationErrorTarget) {
      this.validationErrorTarget.classList.add("hidden")
    }
  }
  
  updateSubmitButton() {
    const submitButton = this.element.querySelector('input[type="submit"]')
    const amountField = document.querySelector('input[name="expense[amount]"]')
    const totalAmount = parseFloat(amountField?.value || 0)
    
    // Check if we're in custom split mode
    const customSplitActive = !this.customSplitTarget.classList.contains("hidden")
    
    if (customSplitActive) {
      const customInputs = this.customSplitTarget.querySelectorAll('input[type="number"]')
      let totalAssigned = 0
      
      customInputs.forEach(input => {
        totalAssigned += parseFloat(input.value || 0)
      })
      
      const remaining = Math.abs(totalAmount - totalAssigned)
      const isValid = remaining < 0.01 // Allow for small floating point errors
      
      if (submitButton) {
        submitButton.disabled = !isValid
        if (isValid) {
          submitButton.classList.remove("opacity-50", "cursor-not-allowed")
        } else {
          submitButton.classList.add("opacity-50", "cursor-not-allowed")
        }
      }
    } else {
      if (submitButton) {
        submitButton.disabled = false
        submitButton.classList.remove("opacity-50", "cursor-not-allowed")
      }
    }
  }

  previewReceipt(event) {
    const file = event.target.files[0]
    if (file && file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        if (this.hasReceiptImageTarget) {
          this.receiptImageTarget.src = e.target.result
          this.receiptPreviewTarget.classList.remove('hidden')
        }
      }
      reader.readAsDataURL(file)
    }
  }

  updateEqualAmounts() {
    // Only update if equal split section is visible
    if (!this.hasEqualSplitTarget || this.equalSplitTarget.classList.contains("hidden")) {
      return
    }
    
    const amountField = document.querySelector('input[name="expense[amount]"]')
    const totalAmount = parseFloat(amountField?.value || 0)
    
    // Find all checked participants in equal split mode
    const checkedParticipants = []
    const checkboxes = document.querySelectorAll('input[name="expense[participant_ids][]"]:checked')
    
    checkboxes.forEach(checkbox => {
      checkedParticipants.push(checkbox.value)
    })
    
    const numParticipants = checkedParticipants.length
    
    // Always update displays, even with 0 amount or 0 participants
    const amountPerPerson = numParticipants > 0 && totalAmount > 0 ? totalAmount / numParticipants : 0
    
    // Update all equal amount displays
    checkedParticipants.forEach(memberId => {
      const target = document.querySelector(`[data-expense-split-target="equalAmount${memberId}"]`)
      if (target) {
        target.textContent = `${amountPerPerson.toFixed(2)} EUR`
      }
    })
    
    // Clear amounts for unchecked participants
    const allCheckboxes = document.querySelectorAll('input[name="expense[participant_ids][]"]')
    allCheckboxes.forEach(checkbox => {
      if (!checkbox.checked) {
        const target = document.querySelector(`[data-expense-split-target="equalAmount${checkbox.value}"]`)
        if (target) {
          target.textContent = '0.00 EUR'
        }
      }
    })
  }

  // Add a method that can be called from data-action attributes
  handleEqualAmountUpdate(event) {
    this.updateEqualAmounts()
  }

  // Toggle participant in custom split mode
  toggleCustomParticipant(event) {
    const checkbox = event.target
    const memberId = checkbox.dataset.memberId
    const input = document.querySelector(`input[name="expense[custom_amounts][${memberId}]"]`)
    
    if (input) {
      if (!checkbox.checked) {
        // If unchecked, clear their amount
        input.value = "0.00"
      }
      // Disable/enable the input field
      input.disabled = !checkbox.checked
      if (!checkbox.checked) {
        input.classList.add('opacity-50')
      } else {
        input.classList.remove('opacity-50')
      }
    }
    
    this.calculateRemaining()
  }
}