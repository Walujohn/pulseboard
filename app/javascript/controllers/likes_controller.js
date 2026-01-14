import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count"]
  static values = { id: Number }

  async like() {
    const res = await fetch(`/status_updates/${this.idValue}/like`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content,
        "Accept": "application/json"
      }
    })

    if (!res.ok) return
    const data = await res.json()
    this.countTarget.textContent = data.likes_count
  }
}
