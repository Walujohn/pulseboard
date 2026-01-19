# Pulseboard: Complete Guide

A Rails 8.1 application demonstrating modern full-stack development with Hotwire, Stimulus, and React.

## Quick Start

```bash
bundle install
rails db:setup
rails server  # http://localhost:3000
```

## Architecture Overview

### Tech Stack
- **Backend**: Rails 8.1 + PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus) + optional React
- **Testing**: RSpec (87 tests, 0 failures)
- **Deployment**: Docker + Kubernetes + Jenkins

### Core Features

**Status Updates Timeline**
- Track status changes over time
- Server-rendered with Hotwire
- Expand/collapse with Stimulus
- Real-time updates with ActionCable + Turbo Streams

**Reactions API**
- React component example (client-side rendering)
- Or use Stimulus (server-rendered approach)
- Demonstrates both paradigms

**Comments API**
- Full CRUD with pagination
- RESTful endpoints
- JSON serialization

---

## Learning Path

### Phase 1: Models & Database
[app/models/](app/models/) - Domain model structure

Key concepts:
- Associations (belongs_to, has_many)
- Validations
- Scopes for querying
- Callbacks (after_update)

### Phase 2: Controllers & API
[app/controllers/](app/controllers/) - Request handling

Key concepts:
- RESTful routing
- Before actions (DRY pattern)
- Response envelopes (JsonResponses concern)
- Error handling (rescue_from)

### Phase 3: Testing & TDD
[spec/](spec/) - 87 passing tests

Key concepts:
- Unit tests (models)
- Integration tests (API endpoints)
- System tests (browser automation)
- FactoryBot fixtures
- Test-driven development workflow

### Phase 4: Controller Refactoring
[app/controllers/concerns/](app/controllers/concerns/) - DRY patterns

Key refactors:
- `before_action :set_resource` - Centralize finds
- `apply_filters(scope)` - Extract filtering logic
- `save_and_respond()` - Consolidate create/update
- `paginated_meta()` - Standardize pagination

### Phase 5: Frontend Architecture
[app/views/](app/views/) + [app/javascript/](app/javascript/) - Browser layer

Key concepts:
- **Hotwire**: Server renders HTML, Turbo updates DOM (no page reload)
- **Stimulus**: JavaScript for interactivity (show/hide, validation)
- **React**: Client-side rendering (complex UIs)
- When to use each

---

## Key Files to Understand

```
Models/Views/Controllers Pattern:

status_updates/
├── models/status_update.rb          ← Domain logic
├── controllers/status_updates_controller.rb  ← HTTP handling
├── serializers/status_change_serializer.rb   ← JSON conversion
└── views/status_updates/            ← HTML templates

Test Pyramid:

spec/
├── models/status_change_spec.rb    ← Unit tests (fast)
├── requests/api_v1_timeline_spec.rb ← Integration tests (medium)
└── system/timeline_spec.rb         ← System tests (slow)

Frontend:

app/javascript/controllers/
├── timeline_item_controller.js     ← Stimulus (expand/collapse)
└── reactions_controller.js         ← Hotwire + fetch pattern

Configuration:

config/
├── routes.rb                       ← URL routing
├── puma.rb                         ← Server settings
└── credentials.yml.enc             ← Secrets (encrypted)
```

---

## How It Works: Request-Response Cycle

### Display Timeline (Hotwire)

```
1. User visits /status_updates/1
2. Rails renders show.html.erb
3. Server includes <div id="timeline"> with data (already rendered)
4. Browser displays complete page
5. Stimulus initializes: wires up click handlers
6. User clicks "Submitted → In Review →" (summary)
7. Stimulus shows hidden details (no server request)
```

### Update Timeline (Turbo Streams)

```
1. User clicks "Save Changes" (mood dropdown)
2. Form submits (Turbo intercepts, no page reload)
3. POST /status_updates/1 with new mood
4. Rails controller updates database
5. Callback fires: StatusChange.create(from: old, to: new)
6. Renders update.turbo_stream.erb (sends Turbo Stream XML)
7. Browser's Turbo library receives: <turbo-stream action="replace" target="timeline">
8. Turbo replaces div#timeline with new HTML
9. Stimulus re-initializes on new HTML
10. User sees updated timeline (no page reload!)
```

### Fetch API (React/Stimulus)

```
JavaScript fetches JSON:
  GET /api/v1/status_updates/1/timeline
  → Returns: { data: [{id: 1, from_status: null, to_status: "submitted"}, ...] }

JavaScript renders HTML from JSON:
  React: Uses state + useState
  Stimulus: Uses querySelector + DOM manipulation
```

---

## Testing Guide

### Run Tests

```bash
# All tests
bundle exec rspec

# Just models (fast)
bundle exec rspec spec/models/

# Just API tests
bundle exec rspec spec/requests/

# Just browser tests (slower)
bundle exec rspec spec/system/

# Single test
bundle exec rspec spec/models/status_change_spec.rb:50

# Watch mode
bundle exec guard
```

### Test Pyramid Strategy

1. **Unit Tests** (models) - Test business logic
   - Validations
   - Scopes
   - Associations
   - Factory methods

2. **Integration Tests** (requests/API) - Test request-response cycle
   - HTTP status codes
   - JSON structure
   - Data serialization
   - Error handling

3. **System Tests** (browser) - Test user experience
   - Navigation
   - Clicks
   - Form submission
   - JavaScript interactions

### Writing Tests (TDD Workflow)

```ruby
# 1. RED: Write failing test
it 'validates presence of status' do
  change = build(:status_change, to_status: nil)
  expect(change).not_to be_valid
end

# 2. GREEN: Write minimal code to pass
validates :to_status, presence: true

# 3. REFACTOR: Clean it up (keep tests green)
# Already clean!

# 4. REPEAT: Add edge cases
it 'allows reason to be nil' do
  change = build(:status_change, reason: nil)
  expect(change).to be_valid
end
```

---

## Performance Tips

### N+1 Query Prevention

```ruby
# ❌ BAD: Separate query per status_update
StatusUpdate.all.each { |s| s.status_changes.count }

# ✅ GOOD: Eager load
StatusUpdate.includes(:status_changes)
```

### Database Indexing

```ruby
# Add indexes to frequently queried columns
add_index :status_changes, :status_update_id
add_index :status_changes, :created_at
add_index :status_updates, :created_at
```

### Caching

```ruby
# Fragment cache (cache HTML pieces)
<% cache @status_update do %>
  <%= render 'timeline' %>
<% end %>

# Query cache
Rails.cache.fetch('statuses', expires_in: 1.hour) do
  StatusUpdate.all
end
```

### Query Optimization

```ruby
# Only fetch needed columns
StatusUpdate.select(:id, :title)

# Sort in database, not Ruby
StatusUpdate.order(created_at: :desc).limit(10)

# Use pagination
StatusUpdate.page(1).per(25)
```

---

## Production Readiness

### Security

```ruby
# CSRF protection (automatic)
# SQL injection prevention (parameterized queries)
StatusUpdate.where(status: params[:status])

# Secrets management
DATABASE_URL = Rails.application.credentials[:database_url]

# HTTPS enforcement
config.force_ssl = true
```

### Monitoring

```bash
# Check logs
docker logs <container>
kubectl logs deployment/pulseboard

# Performance monitoring
EXPLAIN ANALYZE SELECT ...  # PostgreSQL query performance
New Relic / DataDog / Sentry for APM
```

### Deployment

```bash
# Docker
docker build -t pulseboard:latest .
docker run -p 3000:3000 pulseboard:latest

# Kubernetes
kubectl apply -f deployment.yaml
kubectl get pods
kubectl rollout undo deployment/pulseboard  # Rollback

# Jenkins CI/CD
git push → Jenkins builds → Tests → Deploy to staging → Deploy to production
```

---

## Frontend Patterns

### Choose Your Approach

```
Simple CRUD, display data?
→ Use Hotwire (server renders, Turbo updates)

Need show/hide, form feedback?
→ Add Stimulus (JavaScript for interactivity)

Need real-time updates?
→ Add ActionCable + Turbo Streams

Complex state, multi-step workflows?
→ Use React (client-side rendering)
```

### Hotwire Example

```erb
<!-- Server renders complete HTML -->
<div id="timeline" data-turbo-target>
  <%= render 'timeline', changes: @changes %>
</div>

<!-- Form uses Turbo (no page reload) -->
<%= form_with local: true, data: { turbo: true } do |f| %>
  <%= f.select :mood, StatusUpdate::MOODS %>
  <%= f.submit %>
<% end %>
```

### Stimulus Example

```javascript
export default class extends Controller {
  static targets = ['summary', 'details']
  
  toggle() {
    this.detailsTarget.style.display = 
      this.detailsTarget.style.display === 'none' ? 'block' : 'none'
  }
}
```

```erb
<div data-controller="timeline-item">
  <div data-timeline-item-target="summary" 
       data-action="click->timeline-item#toggle">
    Click to expand →
  </div>
  <div data-timeline-item-target="details" style="display: none;">
    Details...
  </div>
</div>
```

### React Example

```javascript
function StatusTimeline({ statusUpdateId }) {
  const [changes, setChanges] = useState([])
  
  useEffect(() => {
    fetch(`/api/v1/status_updates/${statusUpdateId}/timeline`)
      .then(r => r.json())
      .then(d => setChanges(d.data))
  }, [])
  
  return (
    <div>
      {changes.map(c => (
        <div key={c.id}>{c.to_status}</div>
      ))}
    </div>
  )
}
```

---

## Common Tasks

### Add a New Feature

1. **Database**: Create model + migration
2. **Controller**: Add CRUD actions
3. **Tests**: Write tests first (TDD)
4. **Views**: Render HTML (Hotwire) or JSON (API)
5. **Frontend**: Add Stimulus or React if needed
6. **Deploy**: Push to main, Jenkins builds and deploys

### Debug Issue

```bash
# Check logs
rails server -v  # Verbose output
docker logs -f <container>
kubectl logs deployment/pulseboard

# Rails console
rails console
StatusUpdate.first.status_changes.ordered.map(&:to_status)

# Browser DevTools
F12 → Console → Check errors
F12 → Network → Check requests
```

### Performance Issue

```bash
# Find slow queries
EXPLAIN ANALYZE SELECT ...

# Check N+1
Use Bullet gem, see warnings in logs

# Check indexes
rails db:migrate
SELECT * FROM pg_stat_user_indexes WHERE relname = 'status_changes'

# Monitor resources
docker stats
kubectl top pod
```

---

## Next Steps

**You now understand**:
- ✅ Full Rails architecture (models, controllers, views)
- ✅ Testing & TDD (87 tests, red-green-refactor)
- ✅ Refactoring for code quality (DRY principles)
- ✅ Frontend choices (Hotwire vs Stimulus vs React)
- ✅ Production-ready patterns (Docker, K8s, CI/CD)

**What to study next**:

1. **Official Docs** (most authoritative)
   - https://rubyonrails.org
   - https://hotwired.dev (Turbo + Stimulus)
   - https://reactjs.org
   - https://postgresql.org/docs

2. **Your Weak Areas**
   - Not confident with X feature? Build a small project
   - Struggling with performance? Profile your queries
   - Unsure about deployment? Deploy this app to production

3. **Go Deeper**
   - Advanced Rails patterns (Service Objects, Presenters)
   - Advanced Stimulus (Lifecycle hooks, data binding)
   - API design (versioning, rate limiting)
   - Production operations (monitoring, alerting, runbooks)

**You're ready for**:
- ✅ Mid-level engineer roles
- ✅ Building features end-to-end
- ✅ Code reviews and mentoring
- ✅ Architecture decisions
- ✅ Production deployments

---

## Repository Structure

```
pulseboard/
├── app/
│   ├── models/              ← Domain logic
│   ├── controllers/         ← HTTP handling
│   │   ├── api/v1/         ← JSON API
│   │   └── concerns/        ← Shared logic (Paginatable, JsonResponses)
│   ├── serializers/         ← JSON conversion
│   ├── views/              ← HTML templates
│   ├── javascript/         ← Stimulus controllers
│   └── helpers/            ← View helpers
├── config/
│   ├── routes.rb           ← URL routing
│   ├── database.yml        ← DB config
│   └── credentials.yml.enc ← Secrets
├── db/
│   ├── migrate/            ← Schema changes
│   └── schema.rb           ← Current schema
├── spec/
│   ├── models/             ← Unit tests
│   ├── requests/           ← Integration tests
│   └── system/             ← Browser tests
├── Dockerfile              ← Container config
├── docker-compose.yml      ← Multi-container setup
├── Gemfile                 ← Ruby dependencies
└── README.md               ← This file
```

---

## Resources

- **Rails Guides**: https://guides.rubyonrails.org
- **Hotwire Handbook**: https://hotwired.dev
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **Stimulus Handbook**: https://stimulus.hotwired.dev
- **Factory Bot**: https://github.com/thoughtbot/factory_bot
- **RSpec**: https://rspec.info

---

Happy coding! 🚀
