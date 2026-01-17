# Stimulus Controller: Timeline Item Expansion

## What We Built

A **Stimulus controller** that makes timeline items expandable/collapsible.

### Before (Static)
```
Timeline displays all details immediately
User sees everything at once
Timeline is long and potentially overwhelming
```

### After (Interactive with Stimulus)
```
Timeline shows compact summary: "Focused → Happy →"
User clicks summary
Details expand: full timestamps, reasons, etc.
User clicks again
Details collapse
```

---

## How It Works

### The Controller

**File:** `app/javascript/controllers/timeline_item_controller.js`

```javascript
export default class extends Controller {
  toggle() {
    // Find the details element
    const details = this.element.querySelector('.details');
    
    // Toggle visibility
    if (details.style.display === 'none') {
      details.style.display = 'block';
    } else {
      details.style.display = 'none';
    }
    
    // Change arrow: → ↓
    const summary = this.element.querySelector('.summary');
    if (summary.textContent.includes('→')) {
      summary.textContent = summary.textContent.replace('→', '↓');
    } else {
      summary.textContent = summary.textContent.replace('↓', '→');
    }
  }
}
```

### The HTML

**File:** `app/views/status_updates/_timeline.html.erb`

```html
<!-- Stimulus: data-controller connects to timeline_item_controller.js -->
<div class="timeline-item" data-controller="timeline-item">
  
  <!-- SUMMARY: Always visible, clickable -->
  <div class="summary" data-action="click->timeline-item#toggle">
    <strong>Focused</strong> → <strong>Happy</strong> →
  </div>
  
  <!-- DETAILS: Hidden by default, shown on click -->
  <div class="details" style="display: none;">
    <div class="timeline-event">
      <div class="timestamp">Jan 15, 2026 at 10:00 AM</div>
      <div class="reason">"User got promoted"</div>
    </div>
  </div>
  
</div>
```

### The CSS

```css
/* Summary is clickable */
.summary {
  background: #e8f4f8;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.summary:hover {
  background: #d1e8ee;
}

/* Details appear with animation */
.details {
  animation: slideDown 0.2s ease;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

---

## Request-Response Flow

```
1. Page Loads (Hotwire)
   ↓
   Server renders show.html.erb
   Server renders _timeline.html.erb
   
   HTML includes:
   - data-controller="timeline-item"
   - data-action="click->timeline-item#toggle"
   - style="display: none;" on .details
   ↓
   Browser displays timeline (all items collapsed)

2. JavaScript Loads (Stimulus)
   ↓
   Stimulus.js library initializes
   Finds: [data-controller="timeline-item"]
   Loads: timeline_item_controller.js
   Connects controller to each .timeline-item div
   ↓
   Ready for clicks

3. User Clicks Summary
   ↓
   Browser detects: click event on .summary
   Stimulus catches it (data-action specified)
   Calls: timeline_item_controller#toggle()
   ↓
   In toggle():
   - Find .details element
   - Change: display: none → display: block
   - Change: → → ↓ (arrow indicator)
   ↓
   Details animate in (slideDown animation)
   ↓
   User sees full details

4. User Clicks Again
   ↓
   Same flow
   ↓
   In toggle():
   - Find .details element
   - Change: display: block → display: none
   - Change: ↓ → → (arrow indicator)
   ↓
   Details animate out
   ↓
   Back to compact summary
```

---

## Stimulus Anatomy

### `data-controller="timeline-item"`
- Tells Stimulus: "This element uses timeline_item_controller.js"
- One controller per element
- Multiple elements can use the same controller

### `data-action="click->timeline-item#toggle"`
- Syntax: `EVENT->CONTROLLER#METHOD`
- `click` = what event to listen for
- `timeline-item` = which controller (snake_case matches timeline_item_controller.js)
- `toggle` = which method to call
- Examples:
  ```html
  data-action="click->button#press"
  data-action="submit->form#validate"
  data-action="change->filter#update"
  ```

### The Method
```javascript
export default class extends Controller {
  toggle() {  // Called automatically
    // this.element = the [data-controller] element
    // this = the controller instance
  }
}
```

---

## What Stimulus Can Do (Brief Overview)

```javascript
// 1. Respond to events
data-action="click->modal#open"
data-action="change->filter#apply"
data-action="submit->form#validate"

// 2. Target elements
static targets = ['email', 'message']

<input data-modal-target="email">
// In controller:
this.emailTarget  // ← Access the element

// 3. Manage state
this.isOpen = true
// Stimulus remembers it

// 4. Connect/Disconnect
connect() {
  // Runs when element mounted
}

disconnect() {
  // Runs when element removed
}
```

---

## Comparing Approaches

### Without Stimulus (Static)

```erb
<!-- Timeline always shows everything -->
<% changes.each do |change| %>
  <div class="timeline-item">
    <%= change.from_status %> → <%= change.to_status %>
    <div><%= change.created_at %></div>
    <div><%= change.reason %></div>
  </div>
<% end %>
```

**Pro:** Simple, no JavaScript
**Con:** Long page, all details visible, less refined UX

### With Stimulus (Expandable)

```erb
<!-- Timeline shows compact summary -->
<% changes.each do |change| %>
  <div data-controller="timeline-item">
    <div class="summary" data-action="click->timeline-item#toggle">
      <%= change.from_status %> → <%= change.to_status %> →
    </div>
    <div class="details" style="display: none;">
      <div><%= change.created_at %></div>
      <div><%= change.reason %></div>
    </div>
  </div>
<% end %>
```

**Pro:** Clean UX, compact display, interactive, minimal JavaScript
**Con:** Requires Stimulus (small library, worth it)

### With React (Complex)

```jsx
function TimelineItem({ change }) {
  const [expanded, setExpanded] = useState(false);
  
  return (
    <div>
      <div onClick={() => setExpanded(!expanded)}>
        {change.from_status} → {change.to_status} {expanded ? '↓' : '→'}
      </div>
      {expanded && (
        <div>
          <div>{change.created_at}</div>
          <div>{change.reason}</div>
        </div>
      )}
    </div>
  );
}
```

**Pro:** Powerful, full SPA capability
**Con:** Overkill for simple expand/collapse, more code

---

## Testing Your Stimulus Controller

### In Browser Console

```javascript
// Check if Stimulus initialized
console.log(Stimulus)

// Find the controller
const element = document.querySelector('[data-controller="timeline-item"]')
const controller = element.__stimulus_controller  // Debug access

// Manually call the method
controller.toggle()  // Expands/collapses
```

### Manual Testing

1. **Open page:** `http://localhost:3000/status_updates/1`
2. **See timeline** with collapsed summaries
3. **Click on a summary** → details appear with animation
4. **Click again** → details disappear
5. **Try all items** → each works independently

### In DevTools

1. Open DevTools (F12)
2. Elements tab
3. Inspect `.summary` element
4. Right-click → "Break on → click"
5. Click the summary
6. DevTools pauses on click
7. Step through code

---

## Enterprise Pattern (USCIS Global)

### Timeline of Case Status Changes

```html
<!-- Officer dashboard showing case history -->
<div data-controller="case-status-item">
  <div class="summary" data-action="click->case-status-item#toggle">
    SUBMITTED → IN_REVIEW →
  </div>
  
  <div class="details" style="display: none;">
    <p>Changed: Jan 15, 2026 at 2:30 PM</p>
    <p>Changed by: Officer John Smith</p>
    <p>Reason: Initial eligibility check passed</p>
    <p>Documents reviewed: 5</p>
  </div>
</div>
```

**Why useful for USCIS:**
- Officers review many cases (hundreds)
- Timeline is long with many status changes
- Compact view makes dashboard faster
- Click to see full details when needed
- Reduces cognitive load

---

## Next Steps

### If This Works
✅ You've learned Stimulus
✅ You can use it for simple interactivity
✅ Ready for Phase 3: Testing

### To Extend It
```javascript
// Add method to highlight a change
highlight() {
  this.element.classList.add('highlighted')
}

// Add method to copy timestamp
copyTimestamp() {
  const time = this.element.querySelector('.timestamp').textContent
  navigator.clipboard.writeText(time)
}

// In HTML:
<div class="summary" data-action="click->timeline-item#toggle|highlight">
  <!-- Both toggle AND highlight on click -->
</div>
```

### If You Want to Go Deeper
- Learn Stimulus targets (`data-timeline-item-target="details"`)
- Learn Stimulus values (`data-timeline-item-animation-value="true"`)
- Learn Stimulus lifecycle (connect, disconnect)
- Build a form validation controller

---

## Summary

| Concept | What It Does |
|---------|-------------|
| **data-controller** | Connects HTML element to JavaScript controller |
| **data-action** | Listens for event (click, change, submit) and calls method |
| **Controller class** | JavaScript code that handles interactions |
| **toggle()** | Method that shows/hides details |
| **.summary** | Clickable area (compact view) |
| **.details** | Hidden by default, shown on click |
| **Animation** | CSS slideDown effect |

**You now understand:**
- ✅ How Stimulus connects HTML to JavaScript
- ✅ How to trigger methods with data-action
- ✅ When to use Stimulus (simple interactivity)
- ✅ When NOT to use it (complex logic → React)
- ✅ Enterprise UX patterns (USCIS dashboards)

Ready for Phase 3: Testing & TDD? 🚀
