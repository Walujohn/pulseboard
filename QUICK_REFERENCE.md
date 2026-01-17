# Quick Reference: Hotwire vs React

## TL;DR

### HOTWIRE (What We Built)
```ruby
# Controller
def show
  @status_update = StatusUpdate.find(params[:id])
  @changes = @status_update.status_changes  # Server fetches data
end

# View
<div id="timeline">
  <%= render 'timeline', changes: @changes %>  <!-- Server renders HTML -->
</div>

# On update:
respond_to do |format|
  format.turbo_stream  <!-- Sends <turbo-stream> XML to replace DOM -->
end
```

**Flow:** Server renders HTML → Browser displays → Turbo updates DOM

**Stimulus needed?** NO (unless you want click handlers/validation)

### REACT (Also Available)
```jsx
function StatusTimeline({ statusUpdateId }) {
  const [changes, setChanges] = useState([]);
  
  useEffect(() => {
    fetch(`/api/v1/status_updates/${statusUpdateId}/timeline`)
      .then(r => r.json())
      .then(d => setChanges(d.data));
  }, []);

  return (
    <div className="timeline">
      {changes.map(c => <div key={c.id}>...</div>)}
    </div>
  );
}
```

**Flow:** Browser fetches JSON → JavaScript renders HTML → Page updates

**Stimulus needed?** NO (React is JavaScript)

---

## Files You Created

### Hotwire Files (Server-Rendering)
| File | What It Does |
|------|-------------|
| `db/migrate/20260117150000_create_status_changes.rb` | Database table for tracking status changes |
| `app/models/status_change.rb` | Model to represent a status transition |
| `app/models/status_update.rb` | UPDATED: Added `after_update :log_mood_change` callback |
| `app/controllers/status_updates_controller.rb` | UPDATED: Added `show` action, updated `update` action |
| `app/views/status_updates/show.html.erb` | NEW: Shows status update with timeline |
| `app/views/status_updates/_timeline.html.erb` | NEW: Partial that renders timeline (ERB loop) |
| `app/views/status_updates/update.turbo_stream.erb` | UPDATED: Sends Turbo Stream to replace timeline on update |

### React Files (Client-Rendering)
| File | What It Does |
|------|-------------|
| `app/serializers/status_change_serializer.rb` | Converts StatusChange to JSON |
| `app/controllers/api/v1/status_updates_controller.rb` | UPDATED: Added `timeline` action |
| `app/javascript/components/StatusTimeline.jsx` | NEW: React component for timeline |
| `config/routes.rb` | UPDATED: Added API route and web route |

### Documentation
| File | What It Explains |
|------|-----------------|
| `HOTWIRE_vs_REACT.md` | Detailed comparison of both approaches |
| `HOTWIRE_IMPLEMENTATION.md` | How the Hotwire version works |
| `ARCHITECTURE_DIAGRAMS.md` | Visual diagrams of both architectures |

---

## Database Schema

```sql
-- New table created by migration
CREATE TABLE status_changes (
  id bigint PRIMARY KEY,
  status_update_id bigint NOT NULL,  -- Link to parent
  from_status varchar,               -- "focused", "calm", etc.
  to_status varchar NOT NULL,        -- New status
  reason text,                       -- Why it changed (optional)
  created_at timestamp,
  updated_at timestamp,
  FOREIGN KEY (status_update_id) REFERENCES status_updates(id)
);

-- Indexes for fast queries
CREATE INDEX idx_status_changes_on_status_update_id
  ON status_changes(status_update_id);

CREATE INDEX idx_status_changes_on_status_update_and_created
  ON status_changes(status_update_id, created_at);
```

---

## How Hotwire Works (Step by Step)

### Step 1: User Visits Page
```
GET /status_updates/1
  → StatusUpdatesController#show
  → @status_update = StatusUpdate.find(1)
  → @changes = @status_update.status_changes.ordered
  → Render show.html.erb
  → Inside: <%= render 'timeline', changes: @changes %>
  → _timeline.html.erb generates HTML with <% changes.each %>
  → Browser receives COMPLETE HTML
  → Page displays immediately (no JavaScript needed)
```

### Step 2: User Changes Status
```
POST /status_updates/1
{ mood: "happy" }
  → StatusUpdatesController#update
  → @status_update.update(mood: "happy")
  → CALLBACK FIRES: after_update :log_mood_change
    ├─ Gets old mood: "focused"
    ├─ Creates StatusChange.create(from: "focused", to: "happy")
  → @changes = @status_update.status_changes.ordered
  → respond_to { |format| format.turbo_stream }
  → Render update.turbo_stream.erb
  → <turbo-stream action="replace" target="timeline">
    ├─ <template>
    │   <%= render 'timeline', changes: @changes %>
    │ </template>
  → Browser's Turbo library intercepts response
  → Finds div#timeline
  → Replaces its innerHTML with new HTML
  → Page shows new timeline item (NO RELOAD)
```

---

## How React Works (Step by Step)

### Step 1: Component Mounts
```
User visits page
  → Browser loads app.js
  → React mounts <StatusTimeline statusUpdateId={1} />
  → Component runs:
    ├─ const [changes, setChanges] = useState([])
    ├─ useEffect(() => { ... }, [])
    ├─ fetch('/api/v1/status_updates/1/timeline')
  → HTTP GET request sent
```

### Step 2: Server Responds with JSON
```
GET /api/v1/status_updates/1/timeline
  → Api::V1::StatusUpdatesController#timeline
  → @update = StatusUpdate.find(1)
  → @changes = @update.status_changes.ordered
  → render json: {
      data: @changes.map { |c| StatusChangeSerializer.new(c).as_json }
    }
  → Sends JSON response:
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
```

### Step 3: React Renders
```
.then(json => setChanges(json.data))
  → State updates
  → Component re-renders:
    return (
      <div className="timeline">
        {changes.map(change => (
          <div key={change.id}>
            {change.status_display.from} → {change.status_display.to}
          </div>
        ))}
      </div>
    )
  → Browser shows timeline
```

---

## Why No Stimulus Here?

Stimulus = JavaScript Controller Pattern

```javascript
// You'd use Stimulus for this:
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  
  toggle(event) {
    this.itemTargets.forEach(item => {
      item.classList.toggle('hidden')
    })
  }
}
```

```html
<!-- Then in view: -->
<div data-controller="timeline-expander">
  <button data-action="click->timeline-expander#toggle">Expand All</button>
  <div data-timeline-expander-target="item">Item 1</div>
  <div data-timeline-expander-target="item">Item 2</div>
</div>
```

**But our timeline doesn't need this because:**
- ❌ No click handlers
- ❌ No keyboard interaction
- ❌ No form validation
- ✅ Just display data (Turbo does this)
- ✅ Just update HTML (Turbo Stream does this)

→ **Turbo Streams alone are sufficient**

---

## Callbacks: The Magic

When you save a status update, this code runs automatically:

```ruby
# In StatusUpdate model
after_update :log_mood_change

private

def log_mood_change
  if saved_change_to_mood?                    # Did mood change?
    mood_before = saved_changes[:mood][0]     # Get old value
    mood_after = saved_changes[:mood][1]      # Get new value
    
    StatusChange.create(
      status_update: self,
      from_status: mood_before,
      to_status: mood_after
    )
  end
end
```

This means:
```ruby
update = StatusUpdate.find(1)
update.mood = "happy"
update.save!
# ↓ CALLBACK FIRES AUTOMATICALLY
# StatusChange.create(from: "focused", to: "happy")
# ↓ DONE
```

---

## Data at Different Layers

### In Database
```
status_updates table:
  id | body | mood | likes_count | created_at
  1  | "..." | "happy" | 5 | 2026-01-17

status_changes table:
  id | status_update_id | from_status | to_status | created_at
  1  | 1 | null | "focused" | 2026-01-15 10:00
  2  | 1 | "focused" | "calm" | 2026-01-16 14:30
  3  | 1 | "calm" | "happy" | 2026-01-17 09:15
```

### In Hotwire (Server renders)
```erb
<div class="timeline">
  <div class="timeline-item">
    Focused → Calm
    Jan 16 at 02:30 PM
  </div>
</div>
```

### In React (JSON from API)
```json
{
  "data": [
    {
      "id": 1,
      "from_status": "focused",
      "to_status": "calm",
      "status_display": { "from": "Focused", "to": "Calm" }
    }
  ]
}
```

---

## Production Checklist

Before deploying:

- [ ] Run `rails db:migrate` to create `status_changes` table
- [ ] Test: Create a status update
- [ ] Test: Change mood
- [ ] Check: `StatusUpdate.first.status_changes.count` should increase
- [ ] Visit: `/status_updates/1` (Hotwire shows timeline)
- [ ] Fetch: `/api/v1/status_updates/1/timeline` (React gets JSON)
- [ ] Test: Edit form works
- [ ] Test: Turbo Stream replaces timeline (no page reload)
- [ ] No N+1 queries: Use `includes(:status_changes)`
- [ ] CSS styling looks good
- [ ] Timestamps display correctly

---

## Going Forward

### Add Interactivity? Use Stimulus
```html
<!-- Add to _timeline.html.erb -->
<div data-controller="timeline-filter">
  <button data-action="click->timeline-filter#showAll">Show All</button>
  <button data-action="click->timeline-filter#showApproved">Show Approved Only</button>
</div>
```

### Add Real-time Updates? Use ActionCable
```ruby
class StatusUpdateChannel < ApplicationCable::Channel
  def subscribed
    stream_from "status_updates:#{params[:id]}"
  end
end
```

### Need GraphQL? Add Apollo
```graphql
query {
  statusUpdate(id: 1) {
    body
    mood
    changes {
      fromStatus
      toStatus
    }
  }
}
```

---

## Questions This Solves

**Q: Where does the timeline data come from?**
A: Server in Hotwire, API in React. Both query same database.

**Q: How do updates happen without page reload?**
A: Turbo Stream intercepts form, replaces DOM element.

**Q: Why is Hotwire faster?**
A: Server renders HTML once, sends it. React needs JS execution.

**Q: When would you use React instead?**
A: Need offline, complex interactions, or dedicated frontend team.

**Q: Do I need Stimulus?**
A: Only if you want click handlers, validation, or other interactive behavior.

---

## At USCIS Global

**Build with Hotwire if:**
- ✅ Case management (CRUD + display)
- ✅ Officer dashboard (timeline, lists)
- ✅ Document tracking (status updates)
- ✅ Team likes Rails

**Build with React if:**
- ✅ Applicant portal (public web)
- ✅ Complex filtering/search
- ✅ Separate frontend team
- ✅ Mobile app also needed

**Build with Both if:**
- ✅ Internal admin (Hotwire)
- ✅ Public portal (React)
- ✅ Shared API

This is a professional, scalable architecture. 🚀
