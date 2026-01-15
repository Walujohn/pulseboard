import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter", "submit", "errors"]

  connect() {
    this.max = 280
    this.update()
  }

  update() {
    const text = this.inputTarget.value || ""
    const len = text.length

    this.counterTarget.textContent = `${len}/${this.max}`

    // disable submit if empty or too long
    const invalid = len === 0 || len > this.max
    this.submitTarget.disabled = invalid

    // clear errors while typing
    if (this.hasErrorsTarget) this.errorsTarget.textContent = ""
  }

  afterSubmit(event) {
    // event.detail.success is true/false for turbo submit
    if (event.detail.success) {
      this.inputTarget.value = ""
      this.update()
    } else {
      // If server returned 422, you can show a generic message here.
      // (More advanced: parse response text and extract errors.)
      if (this.hasErrorsTarget) {
        this.errorsTarget.textContent = "Please fix the errors and try again."
      }
    }
  }
}
