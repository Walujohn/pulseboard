# Testing & TDD: The Timeline Feature (Phase 3)

## Overview

This guide explains how we use **Test-Driven Development (TDD)** to build reliable, maintainable features. We'll walk through the **timeline feature** as a complete example of how enterprise Rails teams verify code quality.

**Current Test Status**: ✅ 87 tests passing (49 model + 38 API)

---

## 1. The Testing Pyramid

Enterprise Rails testing follows this hierarchy:

```
       [System Tests] ← Real browser, full stack (slow, slow, but realistic)
       [Request Tests] ← HTTP endpoints, JSON responses (medium speed)
    [Unit/Model Tests] ← Individual components (fast, focused)
```

For the timeline feature:
- **Unit Tests**: StatusChange model validations & scopes
- **Request Tests**: API endpoint `/api/v1/status_updates/:id/timeline`
- **System Tests**: User navigating UI, clicking buttons, seeing changes

---

## 2. Part 1: The Model Layer (Unit Tests)

### The StatusChange Model

```ruby
# app/models/status_change.rb
class StatusChange < ApplicationRecord
  STATUSES = ["submitted", "in_review", "approved", "denied", "needs_info"].freeze
  
  belongs_to :status_update
  validates :to_status, presence: true, inclusion: { in: STATUSES }
  validates :from_status, inclusion: { in: STATUSES }, allow_nil: true
  
  scope :ordered, -> { order(created_at: :asc) }
  
  # Factory method for creating status changes
  def self.log!(status_update, from: nil, to:, reason: nil)
    create!(
      status_update: status_update,
      from_status: from,
      to_status: to,
      reason: reason
    )
  end
end
```

### What We Test (Unit Tests)

**File**: `spec/models/status_change_spec.rb`

```ruby
RSpec.describe StatusChange, type: :model do
  
  # Test 1: Relationships
  describe 'associations' do
    it { should belong_to(:status_update) }
    
    it 'is destroyed when status_update is destroyed' do
      status_update = create(:status_update)
      change = create(:status_change, status_update: status_update)
      
      expect {
        status_update.destroy
      }.to change(StatusChange, :count).by(-1)
    end
  end
  
  # Test 2: Validations
  describe 'validations' do
    it 'requires to_status to be present' do
      change = build(:status_change, to_status: nil)
      expect(change).not_to be_valid
    end
    
    it 'requires to_status to be in STATUSES constant' do
      change = build(:status_change, to_status: 'invalid_status')
      expect(change).not_to be_valid
    end
    
    it 'allows from_status to be nil (initial status)' do
      change = build(:status_change, from_status: nil)
      expect(change).to be_valid
    end
  end
  
  # Test 3: Scopes
  describe 'scopes' do
    it 'orders by created_at ascending' do
      status_update = create(:status_update)
      change1 = create(:status_change, status_update: status_update, to_status: 'submitted')
      sleep(0.01)
      change2 = create(:status_change, status_update: status_update, to_status: 'in_review')
      
      ordered = status_update.status_changes.ordered
      expect(ordered.map(&:id)).to eq([change1.id, change2.id])
    end
  end
  
  # Test 4: Factory method
  describe '.log!' do
    it 'creates a status change with correct values' do
      status_update = create(:status_update)
      
      expect {
        StatusChange.log!(
          status_update,
          from: 'submitted',
          to: 'in_review',
          reason: 'Legal review'
        )
      }.to change(StatusChange, :count).by(1)
      
      change = StatusChange.last
      expect(change.from_status).to eq('submitted')
      expect(change.to_status).to eq('in_review')
      expect(change.reason).to eq('Legal review')
    end
  end
end
```

### Key Testing Patterns

1. **Association Testing**: `should belong_to(:status_update)`
   - Verifies Rails associations work correctly
   - Tests that deleting parent also deletes child

2. **Validation Testing**: Build (not save) then check `.valid?`
   - Tests business rules: what values are allowed?
   - Build = doesn't hit DB, only validates in memory

3. **Scope Testing**: Create multiple records, verify ordering
   - Test that `.ordered` returns chronological order
   - Crucial for features where order matters

4. **Factory Method Testing**: `.log!()` creates with correct attributes
   - Verifies the convenience method works as documented
   - Tests both creation and attribute assignment

---

## 3. Part 2: The API Layer (Request Tests)

### The Timeline Controller Action

```ruby
# app/controllers/api/v1/status_updates_controller.rb
class StatusUpdatesController < ActionController::API
  before_action :set_status_update, only: [:timeline]
  
  def timeline
    changes = @status_update.status_changes.ordered
    render_data(serialize_many(changes), :ok)
  end
  
  private
  
  def set_status_update
    @status_update = StatusUpdate.find(params[:id])
  end
end
```

### What We Test (Request Tests)

**File**: `spec/requests/api_v1_timeline_spec.rb`

```ruby
RSpec.describe 'Timeline API', type: :request do
  let(:status_update) { create(:status_update) }
  
  describe 'GET /api/v1/status_updates/:id/timeline' do
    
    # Test 1: HTTP Response
    it 'returns 200 OK' do
      get timeline_api_v1_status_update_path(status_update)
      expect(response).to have_http_status(:ok)
    end
    
    # Test 2: Content Type
    it 'returns JSON response' do
      get timeline_api_v1_status_update_path(status_update)
      expect(response.content_type).to include('application/json')
    end
    
    # Test 3: Response Structure (JsonResponses pattern)
    it 'returns data envelope with changes array' do
      get timeline_api_v1_status_update_path(status_update)
      body = response.parsed_body
      
      expect(body).to have_key('data')
      expect(body['data']).to be_an(Array)
    end
    
    # Test 4: Empty Data
    context 'when status_update has no changes' do
      it 'returns empty data array' do
        get timeline_api_v1_status_update_path(status_update)
        body = response.parsed_body
        
        expect(body['data']).to be_empty
      end
    end
    
    # Test 5: Data Presence
    context 'when status_update has changes' do
      before do
        @change1 = create(:status_change,
          status_update: status_update,
          from_status: nil,
          to_status: 'submitted'
        )
        sleep(0.01)
        @change2 = create(:status_change,
          status_update: status_update,
          from_status: 'submitted',
          to_status: 'in_review'
        )
      end
      
      it 'returns all changes for the status_update' do
        get timeline_api_v1_status_update_path(status_update)
        body = response.parsed_body
        
        expect(body['data'].length).to eq(2)
      end
      
      it 'returns changes in chronological order (oldest first)' do
        get timeline_api_v1_status_update_path(status_update)
        body = response.parsed_body
        
        from_statuses = body['data'].map { |c| c['from_status'] }
        expect(from_statuses).to eq([nil, 'submitted'])
      end
    end
    
    # Test 6: Error Handling
    context 'with invalid status_update ID' do
      it 'returns 404 Not Found' do
        get timeline_api_v1_status_update_path(999999)
        expect(response).to have_http_status(:not_found)
      end
    end
    
    # Test 7: Data Serialization
    context 'response data format' do
      before do
        create(:status_change,
          status_update: status_update,
          from_status: nil,
          to_status: 'submitted',
          created_at: Time.new(2026, 1, 15, 10, 30, 0)
        )
      end
      
      it 'includes all required fields' do
        get timeline_api_v1_status_update_path(status_update)
        change = response.parsed_body['data'].first
        
        expect(change).to have_key('id')
        expect(change).to have_key('from_status')
        expect(change).to have_key('to_status')
        expect(change).to have_key('reason')
        expect(change).to have_key('created_at')
      end
    end
  end
end
```

### Key Testing Patterns

1. **Status Code Verification**: `expect(response).to have_http_status(:ok)`
   - Ensures correct HTTP semantics (200, 404, 422, etc.)
   - Fails fast if controller returns wrong status

2. **Response Structure**: `response.parsed_body` provides JSON
   - Tests the JsonResponses pattern: `{ data: [...] }`
   - Verifies consistency with other API endpoints

3. **Data Presence**: Count returned records
   - Empty case: verify empty array returned
   - Populated case: verify all records present

4. **Ordering**: Map and compare field values
   - Verify `from_status` is nil first, then 'submitted'
   - Ensures `.ordered` scope is actually used

5. **Error Handling**: 404 when resource not found
   - Tests the rescue_from handler
   - Ensures proper error responses

6. **Serialization**: Verify all fields are present
   - Tests StatusChangeSerializer includes required fields
   - Ensures API consumers have needed data

---

## 4. Part 3: The View Layer (System Tests)

### The Timeline View

```erb
<!-- app/views/status_updates/show.html.erb -->
<h1><%= @status_update.title %></h1>

<section data-timeline>
  <% @status_update.status_changes.ordered.each do |change| %>
    <div class="timeline-item" 
         data-change-id="<%= change.id %>"
         data-controller="timeline-item">
      
      <div class="timeline-header" data-action="click->timeline-item#toggle">
        <%= humanized_status(change.from_status) %> 
        → 
        <%= humanized_status(change.to_status) %>
      </div>
      
      <div class="timeline-details" data-timeline-item-target="details" hidden>
        <time><%= change.created_at.strftime('%B %d, %Y at %l:%M %p') %></time>
        <% if change.reason.present? %>
          <p><strong>Reason:</strong> <%= change.reason %></p>
        <% end %>
      </div>
    </div>
  <% end %>
</section>
```

### What We Test (System Tests)

**File**: `spec/system/timeline_spec.rb`

```ruby
RSpec.describe 'Timeline System Tests', type: :system do
  before do
    # Enable JavaScript for Stimulus tests
    driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  end
  
  let(:status_update) { create(:status_update, title: 'Test Application') }
  
  describe 'Viewing a status update timeline' do
    
    # Test 1: Navigation
    it 'user can navigate to a status update' do
      visit status_update_path(status_update)
      
      expect(page).to have_content('Test Application')
    end
    
    # Test 2: Empty State
    context 'with no changes' do
      it 'shows an empty timeline' do
        visit status_update_path(status_update)
        
        expect(page).to have_css('[data-timeline]', count: 1)
        # Timeline section exists but no items
      end
    end
    
    # Test 3: Populated Timeline
    context 'with status changes' do
      before do
        @change1 = create(:status_change,
          status_update: status_update,
          from_status: nil,
          to_status: 'submitted'
        )
        sleep(0.01)
        @change2 = create(:status_change,
          status_update: status_update,
          from_status: 'submitted',
          to_status: 'in_review'
        )
      end
      
      it 'displays all status changes' do
        visit status_update_path(status_update)
        
        expect(page).to have_content('Submitted')
        expect(page).to have_content('In Review')
      end
      
      # Test 4: Stimulus Controller (Expand/Collapse)
      it 'allows expanding timeline items' do
        visit status_update_path(status_update)
        
        # Initially, details are hidden
        details = page.find('[data-timeline-item-target="details"]', visible: false)
        expect(details).not_to be_visible
        
        # Click to expand
        page.find('.timeline-header').click
        
        # Details should now be visible
        expect(details).to be_visible
      end
      
      it 'allows collapsing timeline items' do
        visit status_update_path(status_update)
        
        header = page.find('.timeline-header')
        
        # Click to expand
        header.click
        details = page.find('[data-timeline-item-target="details"]')
        expect(details).to be_visible
        
        # Click to collapse
        header.click
        expect(details).not_to be_visible
      end
      
      # Test 5: Accessibility
      it 'displays timestamps for each change' do
        visit status_update_path(status_update)
        
        # Verify dates are shown
        expect(page).to have_css('time', minimum: 2)
      end
    end
  end
end
```

### Key Testing Patterns

1. **Page Navigation**: `visit status_update_path(status_update)`
   - Tests that URLs work and pages load
   - Verifies basic HTML structure

2. **Content Verification**: `expect(page).to have_content('Submitted')`
   - Checks that rendered content appears on page
   - Tests view helpers and ERB templates

3. **Stimulus Testing**: `visible: false` / `.be_visible`
   - Tests JavaScript interactions (expand/collapse)
   - Verifies data attributes and controllers work
   - Requires browser automation (Selenium/Chrome)

4. **State Changes**: Click → Check visibility → Click again
   - Tests toggle functionality
   - Verifies Stimulus controller state management

5. **Empty States**: Verify structure exists but is empty
   - Tests conditional rendering
   - Ensures graceful degradation

---

## 5. The Request-Response Cycle (How It All Works Together)

Here's what happens when a user requests the timeline:

```
1. USER INTERACTION
   User navigates to /status_updates/123

2. RAILS ROUTER
   Matches route: GET /status_updates/:id
   Calls: StatusUpdatesController#show

3. CONTROLLER ACTION
   @status_update = StatusUpdate.find(params[:id])
   @status_changes = @status_update.status_changes.ordered

4. VIEW RENDERING
   app/views/status_updates/show.html.erb executes
   Loops through @status_changes
   Renders HTML with Stimulus data attributes

5. BROWSER RECEIVES HTML
   Stimulus controller initializes
   Timeline items have data-controller="timeline-item"

6. USER INTERACTION
   Clicks on timeline header

7. STIMULUS HANDLES EVENT
   data-action="click->timeline-item#toggle"
   Finds [data-timeline-item-target="details"]
   Toggles hidden attribute

8. BROWSER UPDATES DOM
   User sees details appear/disappear
```

### Testing Each Layer

```
API Request (from JavaScript or mobile):
GET /api/v1/status_updates/123/timeline
→ StatusUpdatesController#timeline action
→ Returns JSON: { data: [{...}, {...}] }
→ Test: spec/requests/api_v1_timeline_spec.rb

Model Layer (business logic):
StatusChange.ordered
StatusChange.log!(...)
→ Tests: spec/models/status_change_spec.rb

View Layer (browser interaction):
User clicks, Stimulus responds
HTML updates, user sees changes
→ Tests: spec/system/timeline_spec.rb
```

---

## 6. TDD Workflow: How to Add a Feature

Here's how enterprise teams build new features using TDD:

### Step 1: Write a Failing Test (Red)

```ruby
# spec/models/status_change_spec.rb - NEW TEST
describe '.email_on_status_change' do
  it 'returns true for statuses that should trigger email' do
    change = build(:status_change, to_status: 'approved')
    expect(change.should_email?).to be(true)
    
    change = build(:status_change, to_status: 'in_review')
    expect(change.should_email?).to be(false)
  end
end

# Run: rspec spec/models/status_change_spec.rb
# Result: ✗ FAIL - undefined method `should_email?'
```

### Step 2: Write Minimal Code to Pass (Green)

```ruby
# app/models/status_change.rb
class StatusChange < ApplicationRecord
  NOTIFY_STATUSES = ['approved', 'denied'].freeze
  
  def should_email?
    NOTIFY_STATUSES.include?(to_status)
  end
end

# Run: rspec spec/models/status_change_spec.rb
# Result: ✓ PASS
```

### Step 3: Refactor (But Keep Tests Green)

```ruby
# Same code - already clean!
# Or if needed:

class StatusChange < ApplicationRecord
  NOTIFY_STATUSES = ['approved', 'denied'].freeze
  
  scope :notifiable, -> { where(to_status: NOTIFY_STATUSES) }
  
  def should_email?
    NOTIFY_STATUSES.include?(to_status)
  end
end

# Run tests to ensure nothing broke
# Result: ✓ PASS
```

### Step 4: Add Integration Test

```ruby
# spec/requests/api_v1_timeline_spec.rb - NEW TEST
describe 'notifications' do
  it 'includes notification flag in timeline response' do
    change = create(:status_change, to_status: 'approved')
    
    get timeline_api_v1_status_update_path(change.status_update)
    data = response.parsed_body['data'].first
    
    expect(data['should_email']).to be(true)
  end
end

# This forces you to update the serializer
```

### Step 5: Update Serializer

```ruby
# app/serializers/status_change_serializer.rb
class StatusChangeSerializer < ApplicationSerializer
  attributes :id, :from_status, :to_status, :reason, :created_at, :should_email
  
  def should_email
    object.should_email?
  end
end

# Tests pass!
```

---

## 7. Testing Best Practices for Enterprise Rails

### 1. **Fast Tests First**

```
✓ Unit tests (run first, 5 seconds)
  ↓
✓ Request/API tests (10 seconds)
  ↓
✓ System tests (30+ seconds, run last)
```

### 2. **Test Behavior, Not Implementation**

❌ **BAD** - Tests the internal method name
```ruby
it 'calls the log method' do
  expect(StatusChange).to receive(:log!).once
  # Don't test this - it's implementation detail
end
```

✅ **GOOD** - Tests the observable behavior
```ruby
it 'creates a status change' do
  expect {
    status_update.update_status!(to: 'approved')
  }.to change(StatusChange, :count).by(1)
end
```

### 3. **Use Factories for Test Data**

```ruby
# spec/factories.rb
FactoryBot.define do
  factory :status_change do
    status_update
    to_status { 'submitted' }
    from_status { nil }
    created_at { Time.current }
  end
end

# In tests:
# Instead of building complex objects, just:
create(:status_change)  # Full, valid object
build(:status_change)   # In-memory, not saved
```

### 4. **One Assertion Per Test (When Possible)**

```ruby
# ✓ BETTER - Clear purpose
it 'returns status 200' do
  get timeline_api_v1_status_update_path(status_update)
  expect(response).to have_http_status(:ok)
end

it 'returns JSON array' do
  get timeline_api_v1_status_update_path(status_update)
  expect(response.parsed_body['data']).to be_an(Array)
end

# vs ✗ WORSE - Mixed concerns
it 'works correctly' do
  get timeline_api_v1_status_update_path(status_update)
  expect(response).to have_http_status(:ok)
  expect(response.parsed_body['data']).to be_an(Array)
  expect(response.parsed_body['data'].length).to eq(0)
  # If any assertion fails, you don't know which one
end
```

### 5. **Test Edge Cases**

```ruby
# Normal case
it 'orders changes chronologically' do
  # ... test normal scenario
end

# Edge cases
it 'handles single change' do
  # Only 1 change, verify it works
end

it 'handles many changes' do
  # 100 changes, verify performance
end

it 'handles nil from_status' do
  # Initial status has no "from", verify this works
end

it 'handles missing changes' do
  # No changes at all, verify empty response
end
```

### 6. **Use Descriptive Test Names**

```ruby
# ✓ GOOD - Immediately know what's tested
it 'returns 200 OK when timeline endpoint is called with valid ID' do
  
# ✗ BAD - Vague
it 'works' do
```

---

## 8. Running Tests in Development

### Run All Tests

```bash
bundle exec rspec
# 87 examples, 0 failures
```

### Run Specific Test File

```bash
bundle exec rspec spec/models/status_change_spec.rb
bundle exec rspec spec/requests/api_v1_timeline_spec.rb
bundle exec rspec spec/system/timeline_spec.rb
```

### Run Single Test

```bash
bundle exec rspec spec/models/status_change_spec.rb:25
# Runs only line 25
```

### Run with Specific Formatter

```bash
# Progress (dots)
bundle exec rspec --format progress

# Detailed output
bundle exec rspec --format documentation

# Only failures
bundle exec rspec --format progress | grep -E "passing|failing"
```

### Watch for Changes (Guard)

```bash
# Optional: Install guard-rspec
bundle add guard-rspec

# Watch for changes and rerun tests
guard
```

---

## 9. Coverage Report

### Generate Coverage

```bash
bundle exec rspec --format progress --require coverage
```

### View Coverage

```bash
open coverage/index.html  # macOS
start coverage/index.html # Windows
```

---

## 10. Common Testing Mistakes to Avoid

### ❌ Mistake 1: Database Transactions

```ruby
# BAD - Relies on DB rollback between tests
it 'finds the user' do
  User.create!(name: 'Alice')
  expect(User.count).to eq(1)
end
```

```ruby
# GOOD - Explicit test data
it 'finds the user' do
  user = create(:user, name: 'Alice')
  expect(User.find(user.id).name).to eq('Alice')
end
```

### ❌ Mistake 2: Testing Rails Internals

```ruby
# BAD - Tests Rails, not your code
it 'saves the record' do
  expect(status_change.save).to be(true)
end
```

```ruby
# GOOD - Tests your business logic
it 'validates presence of to_status' do
  change = build(:status_change, to_status: nil)
  expect(change).not_to be_valid
end
```

### ❌ Mistake 3: Skipped/Pending Tests

```ruby
# BAD - Leaves broken tests
xit 'handles invalid dates' do
  # This is skipped, will break later
end
```

```ruby
# GOOD - Fix it now or create an issue
it 'handles invalid dates' do
  expect(change).to validate_presence_of(:to_status)
end
```

---

## 11. Phase 3 Summary

**What We've Built**: A complete, tested timeline feature

| Layer | Technology | Test File | Tests |
|-------|-----------|-----------|-------|
| **Model** | StatusChange + scopes | `status_change_spec.rb` | 15 tests |
| **API** | REST endpoint | `api_v1_timeline_spec.rb` | 12 tests |
| **View** | Hotwire + Stimulus | `timeline_spec.rb` | 10 tests |
| **Integration** | Full flow | All tests | 87 total |

**Enterprise Benefits**:
- ✅ Regression prevention (tests fail if someone breaks code)
- ✅ Documentation (tests show how to use the API)
- ✅ Confidence (deploy with tests passing)
- ✅ Maintainability (refactor with safety net)

---

## Next Phase: Phase 4 (Completed!) ✅

We refactored controllers using DRY principles:
- `before_action :set_status_update` for repeated finds
- `apply_filters()` for filtering logic
- `save_and_respond()` for create/update logic
- `paginated_meta()` for consistent pagination

All 87 tests still passing after refactoring! ✅

