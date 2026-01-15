import { Controller } from "@hotwired/stimulus"

/**
 * HOTWIRE EXAMPLE: Reactions Stimulus Controller
 * 
 * This demonstrates the Hotwire approach (Stimulus + Turbo) which:
 * 1. Uses server-rendered HTML + Stimulus for interactivity
 * 2. Sends requests to Rails controllers (not pure API endpoints)
 * 3. Uses Turbo streams for DOM updates
 * 4. Keeps state on the server (simpler, more secure)
 * 
 * This is the "new way" - transforming React logic to Hotwire
 * 
 * Comparison to React approach:
 * - No useState needed (server holds state)
 * - No useEffect needed (HTML loads with data)
 * - Simpler, less JavaScript to maintain
 * - Easier CSRF protection (automatic)
 * - Better SEO (content in HTML)
 */

export default class extends Controller {
  static targets = ["reactionsDisplay", "emojiOption", "reactionButton"]
  static values = { statusUpdateId: Number, userId: String }

  connect() {
    // Called when controller is attached to element
    console.log(`Reactions controller connected for status update ${this.statusUpdateIdValue}`)
  }

  /**
   * Handle emoji reaction click
   * 
   * In React: handleReactionClick() -> fetch POST -> setState -> re-render
   * In Hotwire: toggleReaction() -> fetch POST -> Turbo updates DOM
   */
  async toggleReaction(event) {
    event.preventDefault()
    
    const emoji = event.currentTarget.dataset.emoji
    const button = event.currentTarget
    
    // Disable button during request
    button.disabled = true
    
    try {
      const response = await fetch(
        `/api/v1/status_updates/${this.statusUpdateIdValue}/reactions`,
        {
          method: "POST",
          headers: {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-CSRF-Token": this.csrfToken
          },
          body: JSON.stringify({
            reaction: {
              emoji: emoji,
              user_identifier: this.userIdValue
            }
          })
        }
      )

      if (!response.ok) {
        throw new Error('Failed to toggle reaction')
      }

      // Refresh the reactions display
      // In a real app, you'd parse the response and update just the affected section
      // For now, this demonstrates the pattern
      await this.refreshReactions()
      
    } catch (error) {
      console.error('Error toggling reaction:', error)
      alert('Failed to add reaction. Please try again.')
    } finally {
      button.disabled = false
    }
  }

  /**
   * Refresh reactions from server
   * Could use Turbo.visit() for full page or fetch new HTML fragment
   */
  async refreshReactions() {
    try {
      const response = await fetch(
        `/api/v1/status_updates/${this.statusUpdateIdValue}/reactions`,
        {
          headers: { "Accept": "application/json" }
        }
      )
      
      if (response.ok) {
        const data = await response.json()
        this.updateReactionsDisplay(data.data)
      }
    } catch (error) {
      console.error('Error refreshing reactions:', error)
    }
  }

  /**
   * Update DOM with new reactions data
   * In a real Hotwire app, you'd use Turbo streams from the server instead
   */
  updateReactionsDisplay(reactions) {
    // Clear existing display
    this.reactionsDisplayTarget.innerHTML = ''

    if (reactions.length === 0) {
      this.reactionsDisplayTarget.innerHTML = '<p class="reactions-picker__empty">No reactions yet</p>'
      return
    }

    // Add reaction buttons
    reactions.forEach(reaction => {
      const button = document.createElement('button')
      button.className = 'reaction-button'
      button.onclick = (e) => this.toggleReaction(e)
      button.dataset.emoji = reaction.emoji
      button.innerHTML = `
        <span class="reaction-emoji">${reaction.emoji}</span>
        <span class="reaction-count">${reaction.count}</span>
      `
      this.reactionsDisplayTarget.appendChild(button)
    })
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
}

/**
 * HTML USAGE (server-rendered):
 * 
 * <div class="reactions-picker" 
 *      data-controller="reactions"
 *      data-reactions-status-update-id-value="<%= @status_update.id %>"
 *      data-reactions-user-id-value="<%= session_user_id %>">
 *   
 *   <div class="reactions-picker__display" data-reactions-target="reactionsDisplay">
 *     <%= render "reactions/display", status_update: @status_update %>
 *   </div>
 *   
 *   <div class="reactions-picker__options">
 *     <p class="reactions-picker__label">Add reaction:</p>
 *     <div class="emoji-options">
 *       <% Reaction::EMOJIS.each do |emoji| %>
 *         <button class="emoji-option" 
 *                 data-action="reactions#toggleReaction"
 *                 data-emoji="<%= emoji %>">
 *           <%= emoji %>
 *         </button>
 *       <% end %>
 *     </div>
 *   </div>
 * </div>
 * 
 * KEY DIFFERENCES FROM REACT:
 * 
 * React:
 * - Component manages state in JavaScript
 * - Fetches fresh data on mount
 * - Re-renders on state change
 * - More client-side logic
 * 
 * Hotwire:
 * - Server renders initial HTML
 * - Stimulus adds interactivity layer
 * - Keeps state on server (database)
 * - Server can send Turbo streams for partial updates
 * - Less JavaScript, simpler to understand
 */
