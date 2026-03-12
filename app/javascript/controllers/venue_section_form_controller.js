import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "gaFields", "seatedFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const type = this.typeSelectTarget.value

    if (type === "seated") {
      this.gaFieldsTarget.classList.add("hidden")
      this.seatedFieldsTarget.classList.remove("hidden")
    } else {
      this.gaFieldsTarget.classList.remove("hidden")
      this.seatedFieldsTarget.classList.add("hidden")
    }
  }
}
