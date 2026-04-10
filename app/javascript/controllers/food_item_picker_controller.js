import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "name",
    "foodItemId",
    "unit",
    "category",
    "panel",
    "results",
    "emptyState",
    "summary"
  ]

  static values = {
    items: Array
  }

  connect() {
    this.isOpen = false
    this.activeIndex = -1
    this.filteredItems = []
    this.resetForCustomValue(false)
  }

  search() {
    const query = this.nameTarget.value.trim()
    const exactMatch = this.findExactMatch(query)

    if (exactMatch) {
      this.foodItemIdTarget.value = exactMatch.id
      this.categoryTarget.value = exactMatch.category
      this.replaceUnitOptions(exactMatch.unit_suggestions, this.unitTarget.value || exactMatch.standard_unit)
      this.summaryTarget.textContent = `${this.humanize(exactMatch.category)} · ${exactMatch.standard_unit}`
    } else {
      this.foodItemIdTarget.value = ""
      this.replaceUnitOptions(["kg", "l", "pieces"], this.unitTarget.value || "kg")
      this.summaryTarget.textContent = "Custom item · choose unit and category"
    }

    if (query.length === 0) {
      this.filteredItems = this.itemsValue.slice(0, 8)
    } else {
      this.filteredItems = this.itemsValue
        .filter((item) => this.matches(item, query))
        .slice(0, 8)
    }

    this.renderResults(query)
    this.openPanel()
  }

  focus() {
    this.search()
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closePanel()
    }
  }

  handleKeydown(event) {
    if (!this.isOpen && ["ArrowDown", "ArrowUp"].includes(event.key)) {
      this.search()
      event.preventDefault()
      return
    }

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.moveSelection(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveSelection(-1)
    } else if (event.key === "Enter" && this.isOpen && this.activeIndex >= 0) {
      event.preventDefault()
      this.commitSelection(this.activeIndex)
    } else if (event.key === "Escape") {
      this.closePanel()
    }
  }

  choose(event) {
    const index = Number(event.currentTarget.dataset.index)
    this.commitSelection(index)
  }

  selectCustom() {
    const name = this.nameTarget.value.trim()
    this.resetForCustomValue(true)
    this.nameTarget.value = name
    this.closePanel()
  }

  commitSelection(index) {
    const item = this.filteredItems[index]
    if (!item) return

    this.foodItemIdTarget.value = item.id
    this.nameTarget.value = item.name
    this.categoryTarget.value = item.category
    this.replaceUnitOptions(item.unit_suggestions, item.standard_unit)
    this.summaryTarget.textContent = `${this.humanize(item.category)} · ${item.standard_unit}`
    this.closePanel()
  }

  moveSelection(direction) {
    if (this.filteredItems.length === 0) return

    this.activeIndex = (this.activeIndex + direction + this.filteredItems.length) % this.filteredItems.length
    this.renderResults(this.nameTarget.value.trim())
  }

  renderResults(query) {
    this.resultsTarget.innerHTML = ""
    this.activeIndex = this.filteredItems.length > 0 ? Math.min(this.activeIndex, this.filteredItems.length - 1) : -1

    this.filteredItems.forEach((item, index) => {
      const button = document.createElement("button")
      button.type = "button"
      button.dataset.index = index
      button.dataset.action = "click->food-item-picker#choose"
      button.className = [
        "flex w-full items-center justify-between rounded-2xl px-4 py-3 text-left transition",
        index === this.activeIndex ? "bg-slate-900 text-white" : "bg-white text-slate-900 hover:bg-slate-100"
      ].join(" ")

      button.innerHTML = `
        <span class="min-w-0">
          <span class="block truncate text-sm font-semibold">${item.name}</span>
          <span class="mt-1 block text-xs ${index === this.activeIndex ? "text-slate-300" : "text-slate-500"}">
            ${this.humanize(item.category)} · ${item.standard_unit}
          </span>
        </span>
        <span class="ml-3 rounded-full ${index === this.activeIndex ? "bg-white/10 text-white" : "bg-slate-100 text-slate-600"} px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em]">
          ${item.unit_type}
        </span>
      `

      this.resultsTarget.appendChild(button)
    })

    if (query.length > 0) {
      const customButton = document.createElement("button")
      customButton.type = "button"
      customButton.dataset.action = "click->food-item-picker#selectCustom"
      customButton.className = "mt-2 flex w-full items-center justify-between rounded-2xl border border-dashed border-slate-300 px-4 py-3 text-left text-sm text-slate-700 transition hover:border-slate-400 hover:bg-slate-50"
      customButton.innerHTML = `
        <span>
          <span class="block font-semibold">Use "${query}" as custom item</span>
          <span class="mt-1 block text-xs text-slate-500">Generic unit set, category can be adjusted manually</span>
        </span>
        <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-600">Custom</span>
      `
      this.resultsTarget.appendChild(customButton)
    }

    this.emptyStateTarget.classList.toggle("hidden", this.filteredItems.length > 0)
    this.emptyStateTarget.textContent = query.length > 0 ? "No seeded match yet. You can use this as a custom item." : "Start typing to search seeded items or create a custom item."
  }

  openPanel() {
    this.isOpen = true
    this.panelTarget.classList.remove("hidden")
  }

  closePanel() {
    this.isOpen = false
    this.panelTarget.classList.add("hidden")
  }

  resetForCustomValue(clearName) {
    this.foodItemIdTarget.value = ""
    if (clearName) this.nameTarget.value = ""
    this.categoryTarget.value = "other"
    this.replaceUnitOptions(["kg", "l", "pieces"], this.unitTarget.value || "kg")
    this.summaryTarget.textContent = "Custom item · choose unit and category"
  }

  replaceUnitOptions(units, selectedUnit) {
    const uniqueUnits = [...new Set(units.filter(Boolean))]
    const fallbackUnit = uniqueUnits.includes(selectedUnit) ? selectedUnit : uniqueUnits[0]

    this.unitTarget.innerHTML = ""

    uniqueUnits.forEach((unit) => {
      const option = document.createElement("option")
      option.value = unit
      option.textContent = unit
      option.selected = unit === fallbackUnit
      this.unitTarget.appendChild(option)
    })
  }

  matches(item, query) {
    const normalizedQuery = this.normalize(query)
    return this.searchTerms(item).some((term) => term.includes(normalizedQuery))
  }

  findExactMatch(query) {
    const normalizedQuery = this.normalize(query)
    return this.itemsValue.find((item) => this.normalize(item.name) === normalizedQuery)
  }

  searchTerms(item) {
    const base = [item.name, item.category, item.standard_unit]
    const singular = item.name.endsWith("s") ? item.name.slice(0, -1) : null
    return [...new Set(base.concat(singular).filter(Boolean).map((term) => this.normalize(term)))]
  }

  normalize(value) {
    return value.toLowerCase().trim()
  }

  humanize(value) {
    return value.replaceAll("_", " ").replace(/\b\w/g, (character) => character.toUpperCase())
  }
}
