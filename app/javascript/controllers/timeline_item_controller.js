import { Controller } from "@hotwired/stimulus"

/**
 * TimelineItem Stimulus Controller
 * 
 * Purpose: Toggle expand/collapse on timeline items
 * 
 * Usage:
 *   <div data-controller="timeline-item">
 *     <div class="summary" data-action="click->timeline-item#toggle" data-timeline-item-target="summary">
 *       Click to expand →
 *     </div>
 *     <div class="details" data-timeline-item-target="details" style="display: none;">
 *       Full details here...
 *     </div>
 *   </div>
 * 
 * How it works:
 * 1. User clicks .summary
 * 2. data-action="click->timeline-item#toggle" fires
 * 3. toggle() method is called
 * 4. Uses Stimulus targets instead of querySelector
 * 5. Toggles visibility and updates arrow indicator
 */
export default class extends Controller {
  static targets = ['summary', 'details'];

  /**
   * Toggle details visibility
   * Called when user clicks on summary
   */
  toggle() {
    const isHidden = this.detailsTarget.style.display === 'none';
    
    // Toggle visibility
    this.detailsTarget.style.display = isHidden ? 'block' : 'none';
    
    // Update arrow indicator
    this.#updateArrow(isHidden);
  }

  #updateArrow(wasHidden) {
    const text = this.summaryTarget.textContent;
    const arrow = wasHidden ? '↓' : '→';
    const oldArrow = wasHidden ? '→' : '↓';
    this.summaryTarget.textContent = text.replace(oldArrow, arrow);
  }
}
