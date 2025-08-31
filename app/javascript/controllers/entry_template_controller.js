import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["contentField", "categoryField"]

  applyTemplate(event) {
    event.preventDefault()
    const templateType = event.params.type

    let content = ""
    let category = ""

    switch (templateType) {
      case "food":
        content = "What I ate: \nWhere: \nThoughts: "
        category = "restaurant"
        break
      case "activity":
        content = "What I did: \nWhere: \nThoughts: "
        category = "attraction"
        break
      case "accommodation":
        content = "Where I stayed: \nThoughts: \nAmenities: "
        category = "hotel"
        break
      default:
        content = ""
        category = ""
    }

    this.contentFieldTarget.value = content
    this.categoryFieldTarget.value = category
  }
}