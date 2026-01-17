# Quick Reference: Stimulus Timeline Controller

## What You Built

```
User clicks "Focused → Happy →"
          ↓
Stimulus triggers data-action
          ↓
Controller toggle() method runs
          ↓
Details div changes: display: none → display: block
          ↓
Animation plays (slideDown)
          ↓
User sees full details
          ↓
User clicks again → details hide
```

---

## Files Created/Modified

### NEW
- ✅ `app/javascript/controllers/timeline_item_controller.js` - The Stimulus controller

### MODIFIED
- ✅ `app/views/status_updates/_timeline.html.erb` - Added interactive markup

---

## The Code (Quick View)

### Controller (`timeline_item_controller.js`)

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const details = this.element.querySelector('.details')
    details.style.display = details.style.display === 'none' ? 'block' : 'none'
    
    const summary = this.element.querySelector('.summary')
    const arrow = summary.textContent.includes('→') ? '↓' : '→'
    // Update arrow...
  }
}
```

### HTML (`_timeline.html.erb`)

```erb
<div data-controller="timeline-item">
  <div class="summary" data-action="click->timeline-item#toggle">
    Focused → Happy →
  </div>
  
  <div class="details" style="display: none;">
    Full details here...
  </div>
</div>
```

### CSS

```css
.summary {
  cursor: pointer;
  background: #e8f4f8;
  padding: 0.75rem;
  border-radius: 4px;
}

.summary:hover {
  background: #d1e8ee;
}

.details {
  animation: slideDown 0.2s ease;
}
```

---

## How Stimulus Works (30 Second Version)

```
1. Browser loads page
   ↓
2. Stimulus.js finds: [data-controller="timeline-item"]
   ↓
3. Loads: timeline_item_controller.js
   ↓
4. Wires up: data-action="click->timeline-item#toggle"
   ↓
5. When user clicks .summary:
   - Fire click event
   - Stimulus catches it
   - Call timeline_item_controller.toggle()
   - Show/hide .details
   ↓
6. No page reload, instant response
```

---

## Testing It

### Manual
1. Visit: `http://localhost:3000/status_updates/1`
2. See timeline with collapsed items
3. Click on any "Focused → Happy →" summary
4. Details expand
5. Click again, details collapse
6. Each item works independently

### Browser Console
```javascript
// Find a controller
const el = document.querySelector('[data-controller="timeline-item"]')

// Manually call toggle
el.__stimulus_controller.toggle()

// Should see details appear/disappear
```

---

## Stimulus Concepts

| Concept | Syntax | Example |
|---------|--------|---------|
| **Connect controller** | `data-controller="NAME"` | `data-controller="timeline-item"` |
| **Trigger method** | `data-action="EVENT->CONTROLLER#METHOD"` | `data-action="click->timeline-item#toggle"` |
| **Access element** | `this.element` | `const details = this.element.querySelector('.details')` |
| **Access targets** | `this.TARGET_NAME` | `this.detailsTarget` |
| **Add lifecycle** | `connect()` / `disconnect()` | Runs when added/removed from DOM |

---

## Real-World Example (USCIS)

**Case status timeline in officer dashboard:**

```html
<div data-controller="case-status">
  <div class="summary" data-action="click->case-status#toggle">
    SUBMITTED → IN_REVIEW → APPROVED →
  </div>
  
  <div class="details" style="display: none;">
    <table>
      <tr><td>Status</td><td>Date</td><td>Officer</td></tr>
      <tr><td>SUBMITTED</td><td>Jan 1</td><td>Auto-system</td></tr>
      <tr><td>IN_REVIEW</td><td>Jan 5</td><td>John Smith</td></tr>
      <tr><td>APPROVED</td><td>Jan 15</td><td>Jane Doe</td></tr>
    </table>
  </div>
</div>
```

**Why?**
- Dashboard shows 50 cases (50 timelines)
- Compact view fits on screen
- Click case to see full timeline
- Fast, responsive, no page reload
- Officer productivity increases

---

## What Stimulus IS

✅ Lightweight JavaScript framework (small download)
✅ Works with server-rendered HTML
✅ Great for small interactivity (click, form, hover)
✅ No build step required (just include in Rails)
✅ Hotwire-native (comes with Rails 8)

## What Stimulus ISN'T

❌ Not a full frontend framework (React, Vue, Angular)
❌ Not for complex state management
❌ Not for single-page applications
❌ Not for real-time collaborative features

---

## Next: Phase 3 (Testing)

Now that you understand:
- ✅ Hotwire (server rendering)
- ✅ Turbo Streams (HTML updates)
- ✅ Stimulus (interactivity)
- ✅ React (client rendering)

You're ready to test all of it!

Phase 3 will cover:
- How to test the Stimulus controller
- How to test the timeline partial
- How to test the entire flow
- TDD cycle: Red → Green → Refactor
