# Phase 5: Frontend Architecture Deep Dive

## Overview

You now understand the **testing & TDD** layer. Phase 5 teaches you **how Hotwire and React work** and **when to use each**—critical for enterprise Rails at USCIS/Global scale.

**Current Status**: 87 tests passing ✅ | Controllers refactored ✅ | Full stack understood 🎯

---

## The Frontend Triangle

All three layers work together:

```
           HTML (Server renders)
                  ↓
        ┌─────────┴──────────┐
        ↓                    ↓
    STIMULUS            TURBO STREAMS
    (JavaScript)        (Server-to-Browser)
    Show/hide           Real-time updates
    
    Everything connects at the HTML layer
```

---

## What Each Technology Does

### 1. **Hotwire** = Server-Rendered HTML + Instant Updates

Server sends complete HTML → Browser displays → User updates → Server sends new HTML → Browser replaces (no reload)

```ruby
# Server-side (Rails)
def show
  @status_update = StatusUpdate.find(params[:id])
  @changes = @status_update.status_changes.ordered
  render :show  # Renders full HTML
end

def update
  @status_update.update(status_update_params)
  # Callback creates StatusChange
  respond_to do |format|
    format.turbo_stream  # Sends <turbo-stream> XML
  end
end
```

```erb
<!-- Browser receives this -->
<turbo-stream action="replace" target="timeline">
  <template>
    <%= render 'timeline', changes: @changes %>
  </template>
</turbo-stream>
```

**Turbo.js library does this:**
```javascript
// 1. Intercept form submissions
// 2. Find target="timeline"
// 3. Replace its innerHTML
// 4. Animate the change
// 5. No page reload!
```

**Result**: Fast, reactive updates without JavaScript SPA

---

### 2. **Stimulus** = JavaScript Interactivity (Show/Hide, Click Handlers, Validation)

Browser already has HTML → JavaScript adds interactivity

```javascript
// app/javascript/controllers/timeline_item_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['summary', 'details']
  
  toggle() {
    // HTML is already here, just show/hide it
    this.detailsTarget.style.display = 
      this.detailsTarget.style.display === 'none' ? 'block' : 'none'
  }
}
```

```erb
<!-- HTML with data attributes -->
<div data-controller="timeline-item">
  <div data-timeline-item-target="summary" 
       data-action="click->timeline-item#toggle">
    Submitted → In Review →
  </div>
  
  <div data-timeline-item-target="details" style="display: none;">
    Full details...
  </div>
</div>
```

**Flow**:
```
Browser loads: HTML has both summary and details
              details hidden (style="display: none")
              
Stimulus wire-up: Finds [data-action]
                 Listens for clicks
                 
User clicks: Stimulus calls toggle()
            Details become visible
            
No server request!
```

**Use Stimulus for**:
- ✅ Show/hide elements
- ✅ Form validation feedback
- ✅ Auto-save (silent POST requests)
- ✅ Infinite scroll
- ✅ Search-as-you-type
- ❌ NOT for complete page rebuilds

---

### 3. **React** = Client-Side Rendering (Full SPA)

Server sends JSON → Browser renders HTML with React

```javascript
// Browser-side React (JavaScript)
function StatusTimeline({ statusUpdateId }) {
  const [changes, setChanges] = useState([])
  
  useEffect(() => {
    // Fetch JSON from API
    fetch(`/api/v1/status_updates/${statusUpdateId}/timeline`)
      .then(r => r.json())
      .then(d => setChanges(d.data))
  }, [])
  
  return (
    <div className="timeline">
      {changes.map(c => (
        <div key={c.id}>
          {c.from_status} → {c.to_status}
        </div>
      ))}
    </div>
  )
}
```

```ruby
# Server-side API (same Rails API we have!)
def timeline
  changes = @status_update.status_changes.ordered
  render_data(serialize_many(changes), :ok)
  # Returns JSON: { data: [...] }
end
```

**Flow**:
```
Server returns: { data: [ {id: 1, to_status: 'submitted'}, ... ] }

React receives: JSON array
               
React renders: <div>submitted</div> etc
               
User updates: Sends to server
             Server updates database
             
React re-fetches: Calls useEffect again
                 Updates state
                 Re-renders
```

**Use React for**:
- ✅ Complex UIs with lots of state
- ✅ Full-featured web apps
- ✅ Real-time collaboration (Figma-like)
- ✅ Desktop-like experience
- ❌ NOT for simple CRUD
- ❌ NOT for timeline display

---

## Comparison: Which One to Use?

| Task | Hotwire | Stimulus | React |
|------|---------|----------|-------|
| Display data | ✅ Perfect | ❌ No | ✅ Good |
| Show/hide | ❌ Reload needed | ✅ Perfect | ✅ Overkill |
| Form validation | ❌ Page reload | ✅ Live feedback | ✅ Overkill |
| Real-time updates | ✅ Turbo Streams | ❌ No | ✅ Good |
| Complex state | ❌ Server only | ⚠️ Limited | ✅ Perfect |
| SEO | ✅ HTML in response | ✅ HTML in response | ❌ Client-rendered |
| Bundle size | ✅ Tiny (50KB) | ✅ Small (20KB) | ❌ Large (200KB+) |
| Developer experience | ✅ Familiar (Rails) | ✅ Simple HTML | ⚠️ Complex |

---

## The Request-Response Cycle: All Three Together

### Scenario: User Views Timeline

```
1. USER VISITS /status_updates/1
   ↓
2. Rails Sends HTML (Hotwire)
   <div id="timeline">
     <div class="timeline-item" data-controller="timeline-item">
       <div data-timeline-item-target="summary">Submitted → In Review →</div>
       <div data-timeline-item-target="details" style="display: none;">
         <time>Jan 15, 2026</time>
       </div>
     </div>
   </div>
   ↓
3. Browser Renders HTML
   ↓
4. Stimulus Initializes
   Wires up: [data-action="click->timeline-item#toggle"]
   Ready to respond to clicks
   ↓
5. USER CLICKS "Submitted → In Review →"
   ↓
6. Stimulus Catches Click Event
   Calls timeline_item_controller#toggle()
   ↓
7. JavaScript Updates DOM
   details.style.display = 'block'
   Details become visible
   (No server request!)
   ↓
8. USER CLICKS "SAVE CHANGES" (mood)
   ↓
9. Form Submits to Server (with Turbo)
   POST /status_updates/1
   { mood: "happy" }
   ↓
10. Rails Controller Runs
    @status_update.update(mood: "happy")
    Callback fires: StatusChange.create(...)
    ↓
11. Renders Turbo Stream Response
    <turbo-stream action="replace" target="timeline">
      <template>
        <%= render 'timeline', changes: @changes %>
      </template>
    </turbo-stream>
    ↓
12. Turbo.js Receives Response
    Finds: document.getElementById("timeline")
    Replaces: innerHTML with new HTML
    ↓
13. Stimulus Re-Initializes
    New [data-action] attributes wired up
    ↓
14. USER SEES Updated Timeline
    New status change appears
    Can expand/collapse it (Stimulus)
    No page reload!
```

---

## Real-World Enterprise Patterns (USCIS/Global)

### Case Status Dashboard (Hotwire)

```erb
<!-- app/views/cases/show.html.erb -->
<div id="case-status-timeline">
  <%= render 'status_timeline', case: @case %>
</div>

<!-- Form to update status -->
<%= form_with local: true, data: { turbo: true } do |f| %>
  <%= f.select :status, Case::STATUSES %>
  <%= f.text_area :notes %>
  <%= f.submit "Update Status" %>
<% end %>
```

**What happens**:
1. Officer views case status page
2. Officer selects new status from dropdown
3. Submits form (Turbo intercepts, no page reload)
4. Backend creates StatusChange record
5. Renders Turbo Stream
6. Timeline updates instantly on page
7. Officer sees updated status without context loss

**Why Hotwire here**: Officers work with many cases (100s). Page reload kills productivity. Hotwire keeps page fresh while user works.

---

### Reaction Picker (Stimulus)

```javascript
// app/javascript/controllers/reaction_picker_controller.js
export default class extends Controller {
  static targets = ['button', 'display']
  static values = { statusUpdateId: Number }
  
  async toggleReaction(event) {
    const emoji = event.target.dataset.emoji
    
    // Fetch to update server (async, no wait)
    fetch(`/api/v1/status_updates/${this.statusUpdateIdValue}/reactions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ emoji })
    })
    
    // Update UI immediately (optimistic update)
    this.updateDisplay()
  }
  
  updateDisplay() {
    // Get latest reactions and re-render
    // (Fetch from server or update local display)
  }
}
```

**What happens**:
1. User clicks 👍 emoji
2. Stimulus updates UI immediately (optimistic)
3. Sends async fetch to server (user doesn't wait)
4. Server updates database
5. Response comes back with count
6. Display updates with real count
7. User sees instant feedback

**Why Stimulus here**: Simple interaction. No state management needed. Server holds ground truth. Stimulus just manages UI.

---

### Complex Case Management (React)

```javascript
// app/javascript/components/CaseManagement.jsx
function CaseManagement({ caseId }) {
  const [caseData, setCaseData] = useState(null)
  const [selectedStatus, setSelectedStatus] = useState(null)
  const [notes, setNotes] = useState('')
  const [attachments, setAttachments] = useState([])
  
  // Complex local state
  const handleDragDrop = (files) => { /* ... */ }
  const handleMultipleStatusChanges = () => { /* ... */ }
  const handleWorkflowTransition = () => { /* ... */ }
  
  return (
    <div>
      {/* Complex UI with lots of interactions */}
    </div>
  )
}
```

**What happens**:
1. React component manages entire case workflow
2. User can draft changes without saving
3. Multi-step workflows with conditional steps
4. Drag-drop file upload with progress
5. Real-time validation and dependent fields
6. On save, sends to API

**Why React here**: Complex workflows with many conditional branches. User needs to see all options. React state management shines here.

---

## Performance Considerations

### Hotwire (Fast Initial Load, Slower Updates)
```
Initial page load: 200ms (full HTML from server)
Update after form submit: 150ms (server processes, sends new HTML, Turbo replaces)
User feels: ⚡ Responsive but slight pause on update
Bundle size: 50KB (minimal JavaScript)
```

### Stimulus (Instant Interactions, Zero Server Latency)
```
Click to expand: 0ms (pure JavaScript)
User feels: ⚡⚡ Instant
Bundle size: 20KB additional
```

### React (Slower Initial Load, Instant Updates)
```
Initial page load: 800ms (fetch JSON, React renders)
Update after action: 50ms (state change, re-render, then fetch)
User feels: Slow initial, then ⚡⚡ instant
Bundle size: 200KB+ (React + dependencies)
```

**Enterprise Rule of Thumb**:
- Simple CRUD with occasional updates → **Hotwire**
- Lots of show/hide and form feedback → **Stimulus** (with Hotwire)
- Complex state, real-time collab, desktop-like → **React API** (separate from Rails HTML)

---

## Building the Right Thing

```
Does user need to see updates from OTHER users in real-time?
├─ YES → Use ActionCable (WebSocket) + Hotwire/Stimulus
│   (Broadcasting status changes to all officers viewing same case)
│
└─ NO → Use form submission approach
    ├─ Simple form? → Hotwire (form with data-turbo="true")
    │
    └─ Complex form? → Stimulus (add validation, auto-save, etc.)

Does user need complex client-side state?
├─ YES → React (with API)
│
└─ NO → Hotwire + Stimulus

Is it a full application?
├─ YES → React SPA (with Rails API backend)
│
└─ NO → Hotwire (simpler, faster, less to maintain)
```

---

## The Architecture Decision Tree

```
┌─────────────────────────────────────────────────────┐
│ Build a new feature at USCIS/Global                 │
└────────────────┬────────────────────────────────────┘
                 ↓
        ┌────────────────────┐
        │ Start with Hotwire │
        └─────────┬──────────┘
                  ↓
    ┌─────────────────────────────┐
    │ Add form fields? Dropdowns? │
    │ Need validation feedback?   │
    └──────────┬──────────────────┘
               ↓
    ┌──────────────────────────────┐
    │ Add Stimulus for             │
    │ - Real-time validation       │
    │ - Show/hide conditional fields
    │ - Auto-save drafts           │
    └──────────┬───────────────────┘
               ↓
    ┌──────────────────────────────┐
    │ Need real-time updates from  │
    │ other users?                 │
    └──────────┬───────────────────┘
               ↓
    ┌──────────────────────────────┐
    │ Add ActionCable + Turbo      │
    │ Streams for broadcasting     │
    └──────────────────────────────┘

If complexity grows beyond this → Consider React API
But MOST enterprise features stop at Stimulus + ActionCable
```

---

## Summary: Phase 5 Concepts

✅ **Hotwire** = Server sends HTML, Turbo updates DOM, no page reload
✅ **Stimulus** = Browser adds interactivity to existing HTML
✅ **React** = Browser renders HTML from JSON API

✅ **When to use**:
- Simple CRUD → Hotwire only
- Add interactivity → Hotwire + Stimulus
- Real-time updates → Add ActionCable
- Complex state → React API

✅ **Your Pulseboard app** uses:
- Hotwire for timeline display
- Stimulus for expand/collapse
- React for reaction picker (optional)
- All backed by Rails API

✅ **Enterprise value**:
- Fast development (Hotwire = less code)
- Maintainable (Stimulus is small JS)
- Scalable (API-first architecture)
- SEO-friendly (HTML in response)

---

## What You Can Now Do

✅ Read a Hotwire component and understand the flow
✅ Write Stimulus controllers for interactivity
✅ Know when NOT to use React
✅ Build features the enterprise way
✅ Convert React to Hotwire (or vice versa)
✅ Optimize performance for each approach
✅ Explain tradeoffs to team members

**You now understand the complete Rails stack from database to browser!** 🚀

---

## Next Steps

**Option 1: Real-Time Updates**
Learn ActionCable + Turbo Streams for WebSocket-based updates

**Option 2: Advanced Stimulus**
Learn targets, values, outlets, and lifecycle hooks

**Option 3: API Excellence**
Learn advanced serialization, versioning, and API design

**Option 4: Production Ready**
Learn deployment, monitoring, security, and scaling

What interests you most?
