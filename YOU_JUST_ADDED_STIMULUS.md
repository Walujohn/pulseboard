# You Just Added: Stimulus Interactivity

## What Changed

**Timeline items are now interactive:**

### Before (Static)
```
Timeline Item 1: All details always visible
Timeline Item 2: All details always visible
Timeline Item 3: All details always visible
...
Page is long and cluttered
```

### After (Interactive with Stimulus)
```
Timeline Item 1: "Focused → Happy →" [CLICK TO EXPAND]
Timeline Item 2: "Calm → Blocked →" [CLICK TO EXPAND]
Timeline Item 3: "Happy → Focused →" [CLICK TO EXPAND]

User clicks Item 1:
  ↓ Details expand with animation
  ↓ Timestamp and reason visible
  ↓ Arrow changes → to ↓

User clicks Item 1 again:
  ↓ Details collapse
  ↓ Back to compact summary
```

---

## Files Changed

### Created: `app/javascript/controllers/timeline_item_controller.js`

**What it does:**
- Listens for clicks on `.summary` elements
- Toggles visibility of `.details` elements
- Changes arrow indicator (→ ↔ ↓)

**Language:** JavaScript (using Stimulus framework)

### Modified: `app/views/status_updates/_timeline.html.erb`

**What changed:**
- Added `data-controller="timeline-item"` to timeline items
- Added `data-action="click->timeline-item#toggle"` to summary
- Moved details into hidden div
- Added CSS for summary styling and animation

---

## The Triangle Pattern (Stimulus Edition)

```
HTML Element (with data attributes)
    ↓
[data-controller="timeline-item"]
[data-action="click->timeline-item#toggle"]
    ↓
Stimulus Library (listens for events)
    ↓
When click detected:
    ↓
JavaScript Controller Method (toggle)
    ↓
Manipulates DOM:
    .querySelector('.details')
    .style.display = 'block'
    ↓
Page updates (no refresh)
```

**Contrast with Hotwire:**
- Hotwire: Server sends new HTML → Turbo replaces DOM
- Stimulus: Browser has HTML already → JavaScript shows/hides it

**Contrast with React:**
- React: JavaScript renders HTML from state
- Stimulus: HTML already exists → JavaScript manipulates it

---

## How Stimulus Thinks

### Data Attributes

```html
<!-- This is the "config" -->
<div data-controller="timeline-item">
  <div data-action="click->timeline-item#toggle">
    <!-- When CLICK happens on this element -->
    <!-- Call timeline-item controller's toggle method -->
  </div>
</div>
```

### The Method

```javascript
// This is the "handler"
export default class extends Controller {
  toggle() {
    // this.element = the [data-controller] div
    // Do whatever you want
  }
}
```

### Stimulus Magic

```javascript
// Stimulus automatically:
// 1. Finds [data-controller="timeline-item"]
// 2. Loads timeline_item_controller.js
// 3. Instantiates the class
// 4. Wires up [data-action] listeners
// 5. Calls methods when events happen

// You write: HTML + simple JavaScript
// Stimulus handles: Wiring, connecting, cleaning up
```

---

## When to Use What

```
Display data?
├─ Yep, on page load
│  └─ Use: Hotwire or React
│
├─ Yep, and it's small?
│  └─ Use: Hotwire (server-render)

Need to show/hide existing HTML?
├─ Yep, on click
│  └─ Use: Stimulus
│
├─ Yep, complex state
│  └─ Use: React

Need real-time updates?
├─ Yep, user changes data
│  └─ Use: Hotwire + Turbo Stream (we built this!)
│
├─ Yep, add interactivity
│  └─ Use: Stimulus (we just built this!)

Need complex client-side app?
├─ Yep, lots of features
│  └─ Use: React
```

---

## The Four Hotwire Concepts

You now understand all four:

1. **Turbo Drive** (automatic SPA-like page loads)
   - Normal navigation, but faster
   - Intercepts page clicks

2. **Turbo Frames** (replace sections of page)
   - Show/hide parts of page in response

3. **Turbo Streams** (push updates from server)
   - We built this: `<turbo-stream action="replace" target="timeline">`
   - Timeline updates without page reload

4. **Stimulus** (JavaScript on the server-rendered page)
   - We just built this: expand/collapse timeline items
   - Small, focused JavaScript

**Together:**
- Server renders HTML (Hotwire/ERB)
- Server pushes updates (Turbo Streams)
- Browser adds interactivity (Stimulus)
- No full JavaScript framework needed!

---

## Browser DevTools Testing

### Inspect the Controller

```javascript
// In console:
const element = document.querySelector('[data-controller="timeline-item"]')

// See controller
console.log(element.__stimulus_controllers)

// Call method manually
element.__stimulus_controllers[0].toggle()
```

### Check Data Attributes

1. Open DevTools (F12)
2. Elements tab
3. Find: `<div class="summary"`
4. Right-click → "Inspect Element"
5. See: `data-action="click->timeline-item#toggle"`
6. Click the summary element in page
7. DevTools highlights the element getting clicked

### Network Tab

1. Open DevTools → Network tab
2. Check what happens when you expand an item
3. You should see: **NO network requests** (all local!)
4. This shows: Stimulus works with existing HTML

---

## Code Quality Check

### The Controller
✅ Small (15 lines)
✅ Single responsibility (toggle visibility)
✅ Readable method name (toggle is clear)
✅ Uses standard DOM methods (querySelector, classList)

### The HTML
✅ Semantic markup (summary vs details)
✅ Follows Stimulus conventions (data-controller, data-action)
✅ Accessible (click on div, but could add role="button")
✅ Progressive enhancement (works without CSS, works without JS)

### The CSS
✅ Clean (12 rules)
✅ Uses CSS variables for reusability
✅ Has animation (slideDown)
✅ Hover state for UX

---

## Professional Upgrade Ideas

If you wanted to extend this at USCIS:

```javascript
// 1. Add analytics tracking
toggle() {
  // ... existing code ...
  trackEvent('timeline-item-expanded', { changeId: this.data.get('changeId') })
}

// 2. Add keyboard support (accessibility)
connect() {
  this.element.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') this.toggle()
  })
}

// 3. Add confirmation for sensitive details
toggle() {
  if (!this.isExpanded && this.isSensitive) {
    const confirm = window.confirm("Show sensitive information?")
    if (!confirm) return
  }
  // ... toggle ...
}

// 4. Add multiple targets
static targets = ['summary', 'details']

toggle() {
  this.detailsTarget.style.display = 
    this.detailsTarget.style.display === 'none' ? 'block' : 'none'
}
```

---

## Summary

| What | Why | Where |
|------|-----|-------|
| **Stimulus** | Add interactivity to server-rendered HTML | `timeline_item_controller.js` |
| **data-controller** | Connect HTML to JavaScript controller | `_timeline.html.erb` |
| **data-action** | Trigger methods on events | `_timeline.html.erb` |
| **toggle()** | Show/hide details and change arrow | `timeline_item_controller.js` |

---

## What You Now Know

✅ **Hotwire** = Server renders HTML (fast, simple)
✅ **Turbo Streams** = Server pushes updates (reactive without SPA)
✅ **Stimulus** = Browser adds interactivity (small, focused)
✅ **React** = Client renders HTML (full SPA power)
✅ **When to use each** = Right tool for the job
✅ **Enterprise patterns** = USCIS Global examples

---

## Ready for Phase 3?

You now have a feature to test:
- ✅ Hotwire view (show.html.erb)
- ✅ Hotwire partial (_timeline.html.erb)
- ✅ Stimulus controller (timeline_item_controller.js)
- ✅ Turbo Stream response (update.turbo_stream.erb)
- ✅ React component (StatusTimeline.jsx)

**Phase 3: Testing & TDD** will teach you how to test all of this!

Let's go! 🚀
