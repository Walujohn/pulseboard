# Quick Tour: Stimulus, Serializers, TDD Workflow & Testing Tools

## 1️⃣ Stimulus Controller (JavaScript)

**What it does**: Makes timeline items expand/collapse on click (no page reload)

```javascript
// app/javascript/controllers/timeline_item_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['summary', 'details'];  // ← What to find in HTML

  toggle() {
    // Flip hidden → visible
    const isHidden = this.detailsTarget.style.display === 'none';
    this.detailsTarget.style.display = isHidden ? 'block' : 'none';
    
    // Change arrow: → becomes ↓
    const arrow = isHidden ? '↓' : '→';
    this.summaryTarget.textContent = 
      this.summaryTarget.textContent.replace(/[→↓]/, arrow);
  }
}
```

**How it connects to HTML**:

```erb
<div data-controller="timeline-item">
  <div data-timeline-item-target="summary" 
       data-action="click->timeline-item#toggle">
    Submitted → In Review →
  </div>
  
  <div data-timeline-item-target="details" style="display: none;">
    <time>Jan 15, 2026 at 10:30 AM</time>
  </div>
</div>
```

**Flow**: User clicks → Stimulus catches click → calls `toggle()` → DOM updates → User sees details

---

## 2️⃣ The Serializer (JSON Conversion)

**Problem**: Rails models are Ruby objects, API clients need JSON

**Solution**: Serializer converts objects to JSON

```ruby
# app/serializers/status_change_serializer.rb
class StatusChangeSerializer
  def initialize(status_change)
    @status_change = status_change
  end

  def as_json
    {
      id: @status_change.id,
      from_status: @status_change.from_status,
      to_status: @status_change.to_status,
      reason: @status_change.reason,
      changed_at: @status_change.created_at.iso8601,
      status_display: {
        from: human_readable(@status_change.from_status),
        to: human_readable(@status_change.to_status)
      }
    }
  end

  private

  def human_readable(status)
    return nil if status.nil?
    status.humanize.titleize  # "submitted" → "Submitted"
  end
end
```

**In Controller**:
```ruby
def timeline
  changes = @status_update.status_changes.ordered
  render_data(serialize_many(changes), :ok)
  # ↓ serialize_many calls StatusChangeSerializer
end
```

**JSON Output**:
```json
{
  "data": [
    {
      "id": 1,
      "from_status": null,
      "to_status": "submitted",
      "status_display": {
        "from": null,
        "to": "Submitted"
      },
      "changed_at": "2026-01-15T10:30:00Z"
    }
  ]
}
```

---

## 3️⃣ TDD Workflow: Writing a New Test

**Step 1: Write Failing Test (RED)**

```ruby
# spec/requests/api_v1_timeline_spec.rb
describe 'GET /api/v1/status_updates/:id/timeline' do
  it 'returns reason field for changes with reasons' do
    status_update = create(:status_update)
    create(:status_change, 
      status_update: status_update, 
      to_status: 'approved',
      reason: 'All documents verified')
    
    get timeline_api_v1_status_update_path(status_update)
    body = response.parsed_body
    
    expect(body['data'].first['reason']).to eq('All documents verified')
  end
end
```

Run: `rspec spec/requests/api_v1_timeline_spec.rb`
Result: ✗ **FAIL** - key doesn't exist yet

**Step 2: Write Minimal Code to Pass (GREEN)**

```ruby
# app/serializers/status_change_serializer.rb
def as_json
  {
    id: @status_change.id,
    from_status: @status_change.from_status,
    to_status: @status_change.to_status,
    reason: @status_change.reason,  # ← Add this
    changed_at: @status_change.created_at.iso8601,
    status_display: status_display
  }
end
```

Run: `rspec spec/requests/api_v1_timeline_spec.rb`
Result: ✓ **PASS**

**Step 3: Refactor (Keep Tests Green)**

```ruby
# Nothing to refactor here - already clean!
# Or if needed, improve naming, add comments, etc.
# Run tests again to ensure nothing broke
```

**Step 4: Add Edge Case Test**

```ruby
it 'returns null reason when not provided' do
  status_update = create(:status_update)
  create(:status_change,
    status_update: status_update,
    to_status: 'submitted',
    reason: nil)  # No reason
  
  get timeline_api_v1_status_update_path(status_update)
  body = response.parsed_body
  
  expect(body['data'].first['reason']).to be_nil
end
```

**Result**: TDD workflow prevents bugs before they reach production! ✅

---

## 4️⃣ Phase 5 Preview: Frontend Architecture

**What's Next**:
- How Hotwire (Stimulus + Turbo) works together
- When to use Stimulus vs React
- Real-time updates with Turbo Streams
- Form handling with Stimulus
- Performance optimizations

**Quick Comparison**:

| Need | Tool | Complexity |
|------|------|-----------|
| Click to expand | Stimulus | ⭐ (simple) |
| Toggle dark mode | Stimulus | ⭐ (simple) |
| Real-time notifications | Turbo Streams | ⭐⭐ (medium) |
| Complex UI state | React | ⭐⭐⭐ (complex) |

For Pulseboard timeline: **Stimulus is perfect** (expand/collapse is simple interactivity)

---

## Testing Tools & Concepts (Glossary)

### What is FactoryBot?

Creates test data reliably:

```ruby
# Instead of manually creating objects in each test:
# user = User.create!(name: 'Alice', email: 'alice@example.com', ...)

# Use FactoryBot:
user = create(:user)  # Cleaner, reusable

# Factories live in spec/factories.rb
FactoryBot.define do
  factory :status_change do
    status_update
    to_status { 'submitted' }
    from_status { nil }
    reason { 'Initial submission' }
  end
end
```

**Why it matters**: 
- Same data structure in every test
- Easy to override specific fields
- Central place to change defaults
- Tests stay readable

---

### What are Integration Tests?

Tests that verify **multiple components work together** (request tests are a type):

```ruby
# Unit test: Just one thing
it 'validates to_status presence' do
  change = build(:status_change, to_status: nil)
  expect(change).not_to be_valid
end

# Integration test: Multiple parts together
it 'creates status change via API and returns JSON' do
  # 1. Make HTTP request (Router)
  post api_v1_status_updates_path
  
  # 2. Controller creates model (Model + Controller)
  # 3. Serializer converts to JSON (Serializer)
  # 4. Returns proper response (HTTP)
  
  body = response.parsed_body
  expect(body['data']['to_status']).to eq('submitted')
end
```

**Integration tests verify**: Router → Controller → Model → Serializer → Response

---

### What are System Tests?

Real browser automation testing (what users actually see):

```ruby
it 'user can expand timeline item' do
  # 1. Browser navigates to page
  visit status_update_path(status_update)
  
  # 2. Browser finds element
  summary = page.find('.summary')
  
  # 3. Browser clicks it
  summary.click
  
  # 4. Browser sees result
  details = page.find('.details')
  expect(details).to be_visible
end
```

**Requires**: Selenium + Chrome (real browser driving)

---

### Popular Testing Gems

| Gem | Purpose | Usage |
|-----|---------|-------|
| **RSpec** | Test framework | `bundle exec rspec` |
| **FactoryBot** | Test data | `create(:user)` |
| **Capybara** | Browser interaction | `visit`, `click`, `fill_in` |
| **Selenium** | Real browser driver | Runs Chrome in tests |
| **Shoulda Matchers** | Testing shortcuts | `should validate_presence_of` |

---

### RSpec Matchers You'll Use

```ruby
# Presence
expect(value).to be_present
expect(value).not_to be_nil

# Inclusion
expect([1, 2, 3]).to include(2)
expect('hello').to include('ell')

# Database changes
expect { User.create! }.to change(User, :count).by(1)

# Equality
expect(user.name).to eq('Alice')
expect(user.age).to eql(25)

# Response codes
expect(response).to have_http_status(:ok)
expect(response).to have_http_status(200)

# JSON structure
expect(response.parsed_body).to have_key('data')
expect(response.parsed_body['data']).to be_an(Array)

# Visibility (System tests)
expect(page).to be_visible
expect(page).not_to be_visible
```

---

### Test Organization

```
spec/
├── models/              ← Unit tests (fast)
│   └── status_change_spec.rb
├── requests/            ← Integration tests (medium)
│   └── api_v1_timeline_spec.rb
├── system/              ← System tests (slow, real browser)
│   └── timeline_spec.rb
└── factories.rb         ← Test data definitions
```

**Run Strategy**:
1. All unit tests first (5 seconds)
2. If green, run integration tests (10 seconds)
3. If green, run system tests (30 seconds)
4. If all green, deploy! ✅

---

### Test Naming Convention

```ruby
describe 'StatusChange' do               # What you're testing
  describe 'validations' do              # Category
    it 'requires to_status to be present' do  # Clear behavior
```

**Bad**: `it 'works'`
**Good**: `it 'validates presence of to_status when creating'`

---

## Summary

✅ **Stimulus**: Hotwire framework for JavaScript interactivity (click events, DOM updates)
✅ **Serializer**: Converts Ruby objects to JSON for APIs
✅ **TDD Workflow**: RED (fail) → GREEN (pass) → REFACTOR (clean) → REPEAT
✅ **FactoryBot**: Generates consistent test data
✅ **Integration Tests**: Verify multiple components work together
✅ **System Tests**: Real browser tests (Selenium/Capybara)

**You now understand enterprise Rails testing stack!** 🚀
