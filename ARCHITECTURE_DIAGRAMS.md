# React vs Hotwire: Visual Architecture

## Side-by-Side Comparison

### REACT ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────┐
│                    BROWSER                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  HTML Page (mostly empty)                               │ │
│  │  <div id="root"></div>                                  │ │
│  │                                                         │ │
│  │  JavaScript Loads & Runs:                              │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │ React Component: StatusTimeline                 │   │ │
│  │  │                                                 │   │ │
│  │  │ const [changes, setChanges] = useState([])     │   │ │
│  │  │                                                 │   │ │
│  │  │ useEffect(() => {                             │   │ │
│  │  │   fetch('/api/v1/status_updates/1/timeline') │   │ │
│  │  │     .then(r => r.json())                      │   │ │
│  │  │     .then(d => setChanges(d.data))            │   │ │
│  │  │ }, [])                                         │   │ │
│  │  │                                                 │   │ │
│  │  │ return (                                        │   │ │
│  │  │   <div>{changes.map(c => ...)}</div>          │   │ │
│  │  │ )                                               │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                                                         │ │
│  │  Result: React renders:                                │ │
│  │  <div class="timeline">                                │ │
│  │    <div class="timeline-item">Submitted → In Review</div>
│  │    <div class="timeline-item">In Review → Approved</div>
│  │  </div>                                                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│                          │                                    │
│                          │ HTTP GET                           │
│                          ↓                                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           │
┌──────────────────────────────────────────────────────────────┐
│                      RAILS SERVER                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Route: GET /api/v1/status_updates/1/timeline          │  │
│  │                                                        │  │
│  │ Controller: Api::V1::StatusUpdatesController          │  │
│  │   def timeline                                         │  │
│  │     @update = StatusUpdate.find(params[:id])          │  │
│  │     @changes = @update.status_changes.ordered         │  │
│  │     render json: {                                    │  │
│  │       data: @changes.map { |c| Serializer.new(c) }  │  │
│  │     }                                                 │  │
│  │   end                                                 │  │
│  │                                                        │  │
│  │ Database:                                              │  │
│  │ SELECT * FROM status_changes                          │  │
│  │ WHERE status_update_id = 1                            │  │
│  │ ORDER BY created_at ASC                               │  │
│  │                                                        │  │
│  │ Response (JSON):                                       │  │
│  │ {                                                      │  │
│  │   "data": [                                            │  │
│  │     { "id": 1, "from_status": null,                  │  │
│  │       "to_status": "submitted", "changed_at": "..." }│  │
│  │     { "id": 2, "from_status": "submitted",           │  │
│  │       "to_status": "in_review", ... }                │  │
│  │   ]                                                   │  │
│  │ }                                                      │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘

KEY: Browser does 50% of work (React rendering)
     Server does 50% of work (fetching data)
```

---

### HOTWIRE ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────┐
│                    BROWSER                                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  HTML Page (fully rendered)                             │ │
│  │  <div id="timeline">                                    │ │
│  │    <div class="timeline-item">                          │ │
│  │      Submitted → In Review                             │ │
│  │    </div>                                               │ │
│  │    <div class="timeline-item">                          │ │
│  │      In Review → Approved                              │ │
│  │    </div>                                               │ │
│  │  </div>                                                 │ │
│  │                                                         │ │
│  │  When user updates: form with data-turbo="true"        │ │
│  │  <form action="/status_updates/1" method="POST"        │ │
│  │        data-turbo="true">                              │ │
│  │    <select name="status_update[mood]">...</select>     │ │
│  │  </form>                                                │ │
│  │                                                         │ │
│  │  Turbo.js (automatic, no code needed)                  │ │
│  │  ┌────────────────────────────────────────────────┐    │ │
│  │  │ 1. Intercept form submit (prevent reload)     │    │ │
│  │  │ 2. Send form data as POST request             │    │ │
│  │  │ 3. Receive <turbo-stream> XML response        │    │ │
│  │  │ 4. Parse: action="replace" target="timeline"  │    │ │
│  │  │ 5. Find: document.getElementById("timeline")  │    │ │
│  │  │ 6. Replace: element.innerHTML = newHTML       │    │ │
│  │  │ 7. Page updates (no reload needed!)           │    │ │
│  │  └────────────────────────────────────────────────┘    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                          │                                    │
│                          │ HTTP POST                          │
│                          ↓                                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           │
┌──────────────────────────────────────────────────────────────┐
│                      RAILS SERVER                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Route: PATCH /status_updates/1                        │  │
│  │                                                        │  │
│  │ Controller: StatusUpdatesController                   │  │
│  │   def update                                           │  │
│  │     @status_update = StatusUpdate.find(params[:id])  │  │
│  │     @status_update.update(status_update_params)      │  │
│  │                                                        │  │
│  │     # CALLBACK FIRES: after_update :log_mood_change  │  │
│  │     # StatusChange.create(                            │  │
│  │     #   from_status: "focused",                      │  │
│  │     #   to_status: "happy"                           │  │
│  │     # )                                               │  │
│  │                                                        │  │
│  │     # Refresh data for response                       │  │
│  │     @changes = @status_update.status_changes.ordered │  │
│  │                                                        │  │
│  │     respond_to do |format|                            │  │
│  │       format.turbo_stream                             │  │
│  │       # This renders update.turbo_stream.erb          │  │
│  │     end                                               │  │
│  │   end                                                 │  │
│  │                                                        │  │
│  │ View: update.turbo_stream.erb                         │  │
│  │ <turbo-stream action="replace" target="timeline">    │  │
│  │   <template>                                          │  │
│  │     <%= render 'timeline', changes: @changes %>      │  │
│  │     <!-- Output: Generated HTML from _timeline.erb -->│  │
│  │   </template>                                         │  │
│  │ </turbo-stream>                                       │  │
│  │                                                        │  │
│  │ Response (Turbo Stream XML):                          │  │
│  │ <turbo-stream action="replace" target="timeline">    │  │
│  │   <template>                                          │  │
│  │     <div class="timeline">                            │  │
│  │       <div class="timeline-item">                     │  │
│  │         Submitted → In Review                         │  │
│  │       </div>                                          │  │
│  │       <div class="timeline-item">                     │  │
│  │         In Review → Approved                          │  │
│  │       </div>                                          │  │
│  │       <div class="timeline-item"> <!-- NEW -->        │  │
│  │         Approved → Happy                              │  │
│  │       </div>                                          │  │
│  │     </div>                                            │  │
│  │   </template>                                         │  │
│  │ </turbo-stream>                                       │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘

KEY: Server does 90% of work (renders HTML)
     Browser does 10% of work (Turbo updates DOM)
```

---

## Request/Response Sequence Diagrams

### REACT Timeline: Initial Load

```
Browser                                Server
  │                                      │
  ├─────── GET /status_updates/1 ───────>│
  │                                      │ Renders show.html.erb
  │                                      │ (timeline div is EMPTY)
  │<───────── HTML Response ─────────────┤
  │                                      │
  │ Page loads                           │
  │ React mounts StatusTimeline component
  │                                      │
  ├─ fetch('/api/v1/status_updates/1/timeline')
  │                                      │
  │                    GET /api/v1/status_updates/1/timeline
  │                                      │
  │                    queries DB
  │                    renders JSON
  │<─────────── { "data": [...] } ──────│
  │                                      │
  │ setChanges(json.data)
  │ Component re-renders
  │ .map() creates HTML
  │ DOM updated
  │
  ▼ Timeline visible on page
```

### HOTWIRE Timeline: Initial Load

```
Browser                                Server
  │                                      │
  ├─────── GET /status_updates/1 ───────>│
  │                                      │ Fetches @changes
  │                                      │ Renders show.html.erb
  │                                      │ Renders _timeline.html.erb
  │                                      │ (timeline fully rendered as HTML)
  │<───────── HTML Response ─────────────┤
  │           (includes complete timeline)
  │
  ▼ Timeline visible immediately (no JavaScript needed)
```

### HOTWIRE Timeline: Update

```
Browser                                Server
  │                                      │
  │ User clicks "Save Changes"           │
  │ Form submits (data-turbo="true")    │
  │                                      │
  ├─────── PATCH /status_updates/1 ─────>│
  │ Parameters: { mood: "happy" }        │
  │                                      │ Updates record
  │                                      │ Callback: creates StatusChange
  │                                      │ Fetches @changes
  │                                      │ Renders update.turbo_stream.erb
  │                                      │ (renders _timeline.html.erb
  │                                      │  inside turbo-stream XML)
  │<───── <turbo-stream> XML Response ───┤
  │                                      │
  │ Turbo.js receives response
  │ Parses: action="replace"
  │ Parses: target="timeline"
  │ Finds: div#timeline
  │ Replaces: innerHTML with new HTML
  │
  ▼ Timeline updated (with new status change)
  │ Page still loaded (no reload)
```

---

## Which One Does What?

```
                      ┌─────────────────────────────────────┐
                      │    Task: Show Timeline              │
                      └─────────────────────────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
        ┌───────────▼──────────────┐  ┌──────────▼──────────────┐
        │ REACT (Client-side)      │  │ HOTWIRE (Server-side)  │
        ├──────────────────────────┤  ├──────────────────────────┤
        │ 1. Browser loads app     │  │ 1. Browser requests page│
        │ 2. Fetch JSON from API   │  │ 2. Server renders HTML │
        │ 3. JavaScript processes  │  │ 3. HTML includes data  │
        │ 4. React renders HTML    │  │ 4. Page displays       │
        │ 5. Browser shows result  │  │ 5. No JS needed!       │
        └──────────────────────────┘  └────────────────────────┘
         ❌ Slower first load         ✅ Fast first load
         ✅ SPA feel                  ✅ Simple code
         ⚠️  Needs JavaScript        ✅ SEO friendly
         ✅ Scales well              ✅ Server-side rendering
```

---

## Code Comparison: Timeline Display

### REACT
```jsx
function StatusTimeline({ statusUpdateId }) {
  const [changes, setChanges] = useState([]);
  
  useEffect(() => {
    fetch(`/api/v1/status_updates/${statusUpdateId}/timeline`)
      .then(res => res.json())
      .then(data => setChanges(data.data));
  }, []);

  return (
    <div className="timeline">
      {changes.map((change) => (
        <div key={change.id} className="timeline-item">
          <div>{change.status_display.from} → {change.status_display.to}</div>
          <div>{new Date(change.changed_at).toLocaleString()}</div>
        </div>
      ))}
    </div>
  );
}
```

**Lines of code: 20**
**Network requests: 2 (HTML + API)**
**JavaScript needed: Yes**

### HOTWIRE
```erb
<!-- show.html.erb -->
<div id="timeline">
  <%= render 'timeline', changes: @changes %>
</div>

<!-- _timeline.html.erb -->
<div class="timeline">
  <% changes.each do |change| %>
    <div class="timeline-item">
      <div><%= change.from_status %> → <%= change.to_status %></div>
      <div><%= change.created_at.strftime("%b %d at %I:%M %p") %></div>
    </div>
  <% end %>
</div>
```

**Lines of code: 15**
**Network requests: 1 (HTML only)**
**JavaScript needed: No**

---

## When to Use What?

| Scenario | React | Hotwire |
|----------|-------|---------|
| **Public Dashboard** | ✅ | ✓ |
| **Internal Admin Panel** | ✓ | ✅ |
| **Real-time Updates** | ✅ | ✓ (with ActionCable) |
| **Offline Support** | ✅ | ❌ |
| **Team knows JS well** | ✅ | ✓ |
| **Team knows Rails** | ✓ | ✅ |
| **Fast Initial Load** | ❌ | ✅ |
| **SEO Important** | ❌ | ✅ |
| **Hiring/Scaling** | ✅ (many JS devs) | ✓ (fewer Hotwire experts) |

---

## At USCIS Global: Recommendation

**Use HOTWIRE for:**
- ✅ Case management system (internal)
- ✅ Officer dashboard (fast load)
- ✅ Timeline views (status changes)
- ✅ Forms (validation, submission)
- ✅ Notifications (update counts)

**Use REACT for:**
- ✅ Public-facing applicant portal (SPA feel)
- ✅ Document upload progress
- ✅ Complex filters/search
- ✅ Maps/visualizations

**Use BOTH for:**
- Internal admin (Hotwire, Stimulus for interactivity)
- External applicant portal (React)
- Shared API for both

This is what Netflix, GitHub, and Basecamp do! 🚀
