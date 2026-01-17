# Hotwire Timeline: React vs Hotwire Comparison

## What We Built

A **Status Timeline** feature that displays all status changes for a status update. It exists in **two versions**:
- 🎨 **React Version**: Client-side rendering with `useEffect` hook
- 🚀 **Hotwire Version**: Server-side rendering with Turbo Streams

---

## Version 1: React (Client-Side)

### File: `app/javascript/components/StatusTimeline.jsx`

**How it works:**
```javascript
function StatusTimeline({ statusUpdateId }) {
  const [changes, setChanges] = useState([]);  // State to hold timeline data
  
  useEffect(() => {
    // Fetch from API endpoint when component mounts
    fetch(`/api/v1/status_updates/${statusUpdateId}/timeline`)
      .then(response => response.json())
      .then(json => setChanges(json.data))  // Update state with data
      // State change triggers re-render
  }, [])
}
```

**Data flow:**
```
React Component (Client)
  ↓ (JavaScript runs in browser)
fetch() → HTTP GET
  ↓
Rails API Endpoint: GET /api/v1/status_updates/:id/timeline
  ↓ (Rails responds)
JSON Response: { data: [{...}, {...}] }
  ↓
setChanges() → State update → Re-render
  ↓
Timeline displays on page
```

**Pros:**
- Single Page Application (SPA) feel
- Fast updates without page reload
- Good for real-time dashboards

**Cons:**
- Requires JavaScript to work
- Need to manage loading/error states
- SEO-unfriendly (content not in HTML)
- Extra HTTP request on page load

---

## Version 2: Hotwire (Server-Side Rendering)

### Files:
- `app/controllers/status_updates_controller.rb` - `show` action
- `app/views/status_updates/show.html.erb` - View with timeline
- `app/views/status_updates/_timeline.html.erb` - Timeline partial
- `app/views/status_updates/update.turbo_stream.erb` - Turbo Stream response

### How It Works

#### Step 1: Initial Page Load
```ruby
# app/controllers/status_updates_controller.rb
def show
  @status_update = StatusUpdate.find(params[:id])
  @changes = @status_update.status_changes.ordered  # Fetch on server
end
```

```erb
<!-- app/views/status_updates/show.html.erb -->
<div id="timeline">
  <%= render 'timeline', changes: @changes %>  <!-- Server renders HTML -->
</div>
```

**Result:** HTML is fully rendered on server. Browser receives complete HTML with timeline already in it.

#### Step 2: User Updates Status
```erb
<!-- Form to change status -->
<form action="/status_updates/1" method="POST" data-turbo="true">
  <select name="status_update[mood]">...</select>
  <button>Save changes</button>
</form>
```

When user clicks "Save changes":
1. Form submits to `StatusUpdatesController#update`
2. Rails updates the record
3. `after_update` callback creates `StatusChange` record
4. Renders `update.turbo_stream.erb` (not HTML)

#### Step 3: Turbo Stream Updates Page
```erb
<!-- app/views/status_updates/update.turbo_stream.erb -->
<turbo-stream action="replace" target="timeline">
  <template>
    <%= render 'timeline', status_update: @status_update, changes: @changes %>
  </template>
</turbo-stream>
```

**What this does:**
```
1. Server renders updated timeline HTML
2. Sends Turbo Stream XML response:
   <turbo-stream action="replace" target="timeline">
     <template>NEW HTML HERE</template>
   </turbo-stream>

3. Browser receives Turbo Stream
4. Turbo library finds div#timeline
5. Replaces its contents with NEW HTML
6. Page updates instantly without reload
```

**Data flow:**
```
User Clicks "Save Changes" (in browser)
  ↓
Form submits with data-turbo="true"
  ↓
Rails Controller processes update
  ↓
StatusUpdate#update action runs
  ↓
after_update callback: creates StatusChange record
  ↓
Renders update.turbo_stream.erb (on server)
  ↓
Fetches fresh data: @changes = @status_update.status_changes.ordered
  ↓
Renders partial: _timeline.html.erb as HTML
  ↓
Wraps in <turbo-stream> XML response
  ↓
Browser receives Turbo Stream
  ↓
Turbo JavaScript library finds div#timeline
  ↓
Replaces contents with new HTML
  ↓
Timeline shows updated changes instantly
```

---

## Why No Stimulus?

**Stimulus** is for interactive behavior like:
- Click handlers
- Form validation
- Keyboard shortcuts
- DOM manipulation

**Timeline doesn't need Stimulus because:**
- No click handlers
- No keyboard interaction
- No form validation
- Turbo handles all DOM updates

**When you WOULD use Stimulus:**
```javascript
// Example: Click to expand a timeline item
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    this.element.classList.toggle('expanded')
  }
}
```

Then in HTML:
```erb
<div data-controller="timeline" data-action="click->timeline#toggle">
  Click to expand...
</div>
```

But for our timeline, Turbo Streams are enough!

---

## Comparison Table

| Feature | React | Hotwire |
|---------|-------|---------|
| **Rendering** | Client-side (JavaScript) | Server-side (Rails) |
| **Initial Load** | Blank page + API call | Full HTML from server |
| **SEO** | Bad (content in JS) | Good (HTML in response) |
| **JavaScript** | Required | Optional |
| **Update on Change** | fetch() + setState | Turbo Stream |
| **Time to First Paint** | Slow (wait for JS) | Fast (no JS needed) |
| **Bundle Size** | Large (React library) | Small (Turbo is tiny) |
| **Offline** | Can work offline | Requires server |
| **Real-time** | Easy (WebSocket) | Need ActionCable |

---

## At USCIS Global

### Scenario: Case Status Timeline

```ruby
# Model
class Case < ApplicationRecord
  has_many :case_status_changes, dependent: :destroy
  after_update :log_status_change
end

class CaseStatusChange < ApplicationRecord
  belongs_to :case
end

# Controller
def show
  @case = Case.find(params[:id])
  @changes = @case.case_status_changes.ordered
end
```

### Which approach?

**Use Hotwire (server-rendering + Turbo) if:**
- Internal government system (not public-facing)
- Users mostly update data, don't refresh page
- Performance matters (fast initial load)
- Team prefers Rails over JavaScript
- Need SEO but have mostly internal pages

**Use React if:**
- Public-facing dashboard
- Lots of real-time updates
- Complex client-side interactions
- Team has strong JavaScript expertise
- Need offline functionality

**Use Both if:**
- Admin panel (Hotwire for speed)
- Public dashboard (React for SPA feel)
- Background jobs (WebSocket for updates)

---

## Testing Checklist

- [ ] Migrations run: `rails db:migrate`
- [ ] StatusChange model validates
- [ ] Timeline partial renders without errors
- [ ] Show page displays timeline
- [ ] Update form works
- [ ] Turbo Stream response replaces timeline
- [ ] React component fetches from API
- [ ] New status changes appear in timeline

---

## Next Steps

1. **Run migrations:**
   ```bash
   rails db:migrate
   ```

2. **Create seed data:**
   ```ruby
   # db/seeds.rb
   update = StatusUpdate.create(body: "Test", mood: "focused")
   update.update!(mood: "calm")  # Creates a StatusChange
   update.update!(mood: "happy") # Creates another StatusChange
   ```

3. **Test Hotwire version:**
   - Go to `/status_updates/:id`
   - Click "Change Status"
   - Edit mood
   - Watch timeline update with Turbo Stream

4. **Test React version:**
   - Mount component: `<StatusTimeline statusUpdateId={1} />`
   - Component fetches from `/api/v1/status_updates/1/timeline`
   - Timeline renders from JSON

---

## Key Takeaway

**Hotwire = Server renders, Turbo updates (HTML over HTTP)**
**React = Client renders, fetch updates (JSON over HTTP)**

Both work. Hotwire is simpler and faster for CRUD apps. React is better for SPA experiences.

For Pulseboard/USCIS timeline: **Hotwire is probably better** because:
- Simpler code
- Faster initial load
- No complex JavaScript state
- SEO still works
- Rails developers understand it
