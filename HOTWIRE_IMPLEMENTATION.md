# Architecture: Hotwire Implementation Summary

## Files Created/Modified

### Database Layer
- ✅ `db/migrate/20260117150000_create_status_changes.rb` - New migration
- ✅ `app/models/status_change.rb` - New model

### API Layer (for React)
- ✅ `app/serializers/status_change_serializer.rb` - JSON serializer
- ✅ `config/routes.rb` - Added `GET /api/v1/status_updates/:id/timeline`
- ✅ `app/controllers/api/v1/status_updates_controller.rb` - Added `timeline` action

### Web Layer (for Hotwire)
- ✅ `config/routes.rb` - Added `:show` to web routes
- ✅ `app/controllers/status_updates_controller.rb` - Added `show` action, updated `update` action
- ✅ `app/views/status_updates/show.html.erb` - New show page with timeline
- ✅ `app/views/status_updates/_timeline.html.erb` - New partial
- ✅ `app/views/status_updates/edit.html.erb` - Updated to be prettier
- ✅ `app/views/status_updates/update.turbo_stream.erb` - Turbo Stream response

### Frontend (React)
- ✅ `app/javascript/components/StatusTimeline.jsx` - React component

### Model Updates
- ✅ `app/models/status_update.rb` - Added association, added `after_update` callback

### Documentation
- ✅ `HOTWIRE_vs_REACT.md` - Comprehensive comparison

---

## Data Structure

### StatusChange Table
```sql
CREATE TABLE status_changes (
  id bigint PRIMARY KEY,
  status_update_id bigint NOT NULL FOREIGN KEY,
  from_status varchar,        -- "focused", "calm", "happy", "blocked"
  to_status varchar NOT NULL,
  reason text,                -- Optional explanation
  created_at timestamp,
  updated_at timestamp,
  
  INDEX: (status_update_id)
  INDEX: (status_update_id, created_at)
)
```

### StatusUpdate Changes
```ruby
has_many :status_changes, dependent: :destroy
after_update :log_mood_change  # Automatically tracks mood transitions
```

---

## Request-Response Flows

### HOTWIRE FLOW (Server-rendered, Turbo updates)

```
1. USER LOADS PAGE
   GET /status_updates/1
   ↓
   StatusUpdatesController#show action
   @status_update = StatusUpdate.find(1)
   @changes = @status_update.status_changes.ordered
   ↓
   render :show (uses show.html.erb)
   ↓
   Inside show.html.erb:
   <%= render 'timeline', status_update: @status_update, changes: @changes %>
   ↓
   _timeline.html.erb renders HTML (with loop: <% changes.each do |change| %>)
   ↓
   Browser receives complete HTML with timeline already there
   ↓
   DISPLAY: Full status update page with timeline

2. USER UPDATES STATUS (clicks "Save changes")
   POST /status_updates/1
   Parameters: { status_update: { mood: "happy" } }
   ↓
   StatusUpdatesController#update action
   @status_update.update(mood: "happy")
   ↓
   CALLBACK FIRES: after_update :log_mood_change
   StatusChange.create(from_status: "focused", to_status: "happy")
   ↓
   Fetch fresh data:
   @changes = @status_update.status_changes.ordered
   ↓
   respond_to do |format|
     format.turbo_stream  # This renders update.turbo_stream.erb
   ↓
   Turbo Stream response sent:
   <turbo-stream action="replace" target="timeline">
     <template>
       <%= render 'timeline', changes: @changes %>
     </template>
   </turbo-stream>
   ↓
   Browser's Turbo JavaScript library receives response
   ↓
   Turbo finds: document.getElementById("timeline")
   ↓
   Replaces its innerHTML with new HTML from template
   ↓
   DISPLAY: Timeline updated with new status change (animated)
```

### REACT FLOW (Client-rendered, fetch updates)

```
1. USER LOADS PAGE
   GET /status_updates/1 (no timeline)
   ↓
   Browser loads React component
   ↓
   <StatusTimeline statusUpdateId={1} />
   ↓
   Component mounts
   ↓
   useEffect hook fires
   ↓
   fetch('/api/v1/status_updates/1/timeline')
   ↓
   Api::V1::StatusUpdatesController#timeline action
   @status_update = StatusUpdate.find(1)
   @changes = @status_update.status_changes.ordered
   ↓
   Serialize and render JSON:
   render json: {
     data: @changes.map { |c| StatusChangeSerializer.new(c).as_json }
   }
   ↓
   JSON response:
   {
     "data": [
       {
         "id": 1,
         "from_status": null,
         "to_status": "focused",
         "changed_at": "2026-01-15T10:00:00Z",
         "status_display": { "from": null, "to": "Focused" }
       },
       ...
     ]
   }
   ↓
   React receives JSON
   ↓
   .then(json => setChanges(json.data))
   ↓
   State update triggers re-render
   ↓
   DISPLAY: Timeline renders via changes.map()

2. FOR UPDATES: Would need separate mechanism
   - Could use polling (refetch every N seconds)
   - Could use WebSocket (ActionCable)
   - Or user manually refetches
```

---

## Key Concepts

### Hotwire Pattern: Server → HTML → Browser → Turbo

```
Server renders HTML (ERB)
  ↓
Wraps in <turbo-stream> XML
  ↓
Sends to browser (no JSON parsing needed)
  ↓
Turbo.js (small library) finds target element
  ↓
Replaces DOM
  ↓
Browser shows update (no page reload)
```

**Advantage:** Rails developers feel at home (still writing HTML/ERB)

### React Pattern: Server → JSON → Browser → JavaScript Renders

```
Server provides data only (JSON API)
  ↓
JavaScript must parse JSON
  ↓
React component renders HTML from JSON
  ↓
Browser shows rendered content
```

**Advantage:** Full separation of concerns (backend API, frontend app)

---

## Why No Stimulus Here?

```javascript
// Stimulus is for this:
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    this.element.classList.toggle('expanded')
  }
}
```

But our timeline doesn't have interactive behaviors. It just:
1. Displays data (Turbo handles this with HTML replacement)
2. Updates on submit (Turbo Stream handles this)
3. No click handlers, validations, or DOM manipulation needed

→ **Turbo Streams alone are sufficient**

---

## Testing This Locally

### Step 1: Run Migration
```bash
rails db:migrate
```

### Step 2: Create Test Data
```ruby
# In rails console
update = StatusUpdate.create(body: "Getting started", mood: "focused")
update.update!(mood: "calm")      # Creates StatusChange #1
update.update!(mood: "happy")     # Creates StatusChange #2

# Check timeline
update.status_changes.ordered
# => [StatusChange(from: "focused", to: "calm"), StatusChange(from: "calm", to: "happy")]
```

### Step 3: Visit the Page
- **Hotwire:** Visit `http://localhost:3000/status_updates/1`
  - Should see complete timeline immediately
  - Click "Change Status"
  - Update mood and save
  - Timeline updates with Turbo Stream (no page reload)

- **React API:** Fetch from console
  ```javascript
  fetch('/api/v1/status_updates/1/timeline')
    .then(r => r.json())
    .then(d => console.log(d.data))
  ```
  - Should see array of status changes as JSON

---

## Production Readiness Checklist

- [ ] `StatusChangeSerializer` returns correct JSON shape
- [ ] `_timeline.html.erb` renders without errors
- [ ] `update.turbo_stream.erb` targets correct element IDs
- [ ] After-update callback creates records (check database)
- [ ] No N+1 queries (use `.includes` if needed)
- [ ] Timeline partial has correct CSS classes
- [ ] Turbo is loaded in layout (should be default in Rails 8)
- [ ] Tests pass for model, controller, views
- [ ] React component is mounted in application.js if using React

---

## Files at a Glance

| File | Purpose | Framework |
|------|---------|-----------|
| `status_change.rb` | Model | Rails |
| `_timeline.html.erb` | Display timeline | ERB (Hotwire) |
| `show.html.erb` | Show page | ERB (Hotwire) |
| `update.turbo_stream.erb` | Update response | Turbo Stream |
| `StatusTimeline.jsx` | Display timeline | React |
| `status_changes_controller.rb` | API endpoint | Rails API |

---

## Next: What We Learned

✅ **Hotwire = Server rendering + Turbo Stream updates (no JavaScript needed for basic CRUD)**
✅ **React = Client rendering + fetch JSON (full SPA experience)**
✅ **Stimulus = For interactivity (not needed here)**
✅ **Timeline auto-tracks mood changes via `after_update` callback**
✅ **Both approaches coexist** (API for React, web routes for Hotwire)

You can now:
- Read a Hotwire component and understand the flow
- Convert React to Hotwire (or vice versa)
- Know when to use Stimulus (when you need interactivity)
- Build real-world enterprise features at USCIS Global
