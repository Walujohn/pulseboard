# Phase 3: Testing & TDD - Timeline Feature Complete Guide

## Overview

This document explains how we test the timeline feature and WHY we test it that way. This is enterprise-grade testing that prevents bugs, documents behavior, and enables safe refactoring.

**The Four Layers of Tests We Created:**

1. **Model Tests** (`spec/models/status_change_spec.rb`)
   - Test the data layer
   - Verify database validations
   - Test business logic methods
   - Test associations

2. **Request/Controller Tests** (`spec/requests/api_v1_timeline_spec.rb`)
   - Test HTTP endpoints
   - Verify response format and status codes
   - Test the request-response cycle
   - Verify JSON serialization

3. **System Tests** (`spec/system/timeline_spec.rb`)
   - Test real browser interaction
   - Verify Stimulus controllers work
   - Test complete user journeys
   - Test accessibility

4. **(Future) JavaScript Tests**
   - Test Stimulus controller logic
   - Test DOM manipulation
   - Test event handling

---

## 1. Model Testing (Foundation Layer)

### What We Test

```ruby
# File: spec/models/status_change_spec.rb

describe StatusChange do
  # 1. Associations
  it { should belong_to(:status_update).dependent(:destroy) }

  # 2. Validations
  it { should validate_presence_of(:to_status) }
  it { should validate_inclusion_of(:to_status).in_array(StatusChange::STATUSES) }

  # 3. Constants
  describe 'STATUSES' do
    it { expect(StatusChange::STATUSES).to be_frozen }
  end

  # 4. Factory Methods
  describe '.log!' do
    it 'creates a status change' do
      status_update = create(:status_update)
      change = StatusChange.log!(
        status_update,
        from: 'submitted',
        to: 'in_review'
      )
      expect(change).to be_persisted
    end
  end

  # 5. Scopes
  describe '.ordered' do
    it 'returns changes in creation order' do
      # oldest first
    end
  end
end
```

### Why Model Tests Matter

- **Speed**: Fastest tests - run in milliseconds
- **Isolation**: No database transactions, no HTTP calls
- **Clarity**: Each test is independent
- **Documentation**: Code becomes clear about requirements

### Example: The `.log!` Factory Method

```ruby
# Model: app/models/status_update.rb
def log_mood_change
  return unless saved_change_to_mood?
  from_status, to_status = saved_changes[:mood]
  StatusChange.log!(self, from: from_status, to: to_status)
end

# Test: spec/models/status_change_spec.rb
describe '.log!' do
  it 'creates a change record' do
    status_update = create(:status_update)
    change = StatusChange.log!(status_update, from: nil, to: 'submitted')
    
    expect(change.status_update_id).to eq(status_update.id)
    expect(change.from_status).to be_nil
    expect(change.to_status).to eq('submitted')
  end
end
```

**What this test verifies:**
- The `.log!` method creates a database record
- It associates with the correct status_update
- It stores from/to statuses correctly
- It's called when a status changes (integration test)

---

## 2. Request Testing (API Layer)

### What We Test

The HTTP request-response cycle:

```
Client Request
    ↓
HTTP GET /api/v1/status_updates/:id/timeline
    ↓
Rails Router
    ↓
StatusUpdatesController#timeline
    ↓
StatusChange.where(status_update_id: id).ordered
    ↓
StatusChangeSerializer (converts to JSON)
    ↓
JsonResponses#render_data (wraps in envelope)
    ↓
HTTP Response (200 OK + JSON body)
    ↓
Client receives: { data: [...] }
```

### Example Test

```ruby
# File: spec/requests/api_v1_timeline_spec.rb

describe 'GET /api/v1/status_updates/:id/timeline' do
  let(:status_update) { create(:status_update) }
  
  it 'returns 200 OK' do
    get api_v1_status_update_timeline_path(status_update)
    expect(response).to have_http_status(:ok)
  end

  it 'returns JSON response' do
    get api_v1_status_update_timeline_path(status_update)
    expect(response.content_type).to include('application/json')
  end

  it 'returns data envelope' do
    create(:status_change, status_update: status_update)
    get api_v1_status_update_timeline_path(status_update)
    
    body = response.parsed_body
    expect(body['data']).to be_an(Array)
  end

  it 'includes to_status field' do
    create(:status_change, status_update: status_update, to_status: 'submitted')
    get api_v1_status_update_timeline_path(status_update)
    
    body = response.parsed_body
    expect(body['data'].first['to_status']).to eq('submitted')
  end
end
```

### Key Concepts

**1. Test the Status Code**
```ruby
expect(response).to have_http_status(:ok)        # 200
expect(response).to have_http_status(:not_found) # 404
```

**2. Test the Response Format**
```ruby
body = response.parsed_body
expect(body).to have_key('data')              # Has correct structure
expect(body['data']).to be_an(Array)          # Is array, not object
```

**3. Test the Data**
```ruby
change = create(:status_change, to_status: 'approved')
get api_v1_status_update_timeline_path(status_update)
body = response.parsed_body

expect(body['data'].first['to_status']).to eq('approved')
```

**4. Test the Serialization**
```ruby
# StatusChangeSerializer converts this:
# { id: 1, status_update_id: 5, to_status: 'approved', ... }

# To this (humanized for client):
# { 
#   id: 1, 
#   to_status: 'approved',
#   status_display: { from: nil, to: 'Approved' },
#   changed_at: '2026-01-17T10:30:45Z',
#   reason: null
# }

it 'humanizes status labels' do
  create(:status_change, status_update: status_update, to_status: 'in_review')
  get api_v1_status_update_timeline_path(status_update)
  
  body = response.parsed_body
  expect(body['data'].first['status_display']['to']).to eq('In Review')
end
```

### Why Request Tests Matter

- **Integration**: Test actual HTTP layer
- **Real Data Flow**: Serializers, response format
- **API Contracts**: Document what client expects
- **Regression Prevention**: Catch breaking changes

---

## 3. System Testing (End-to-End Layer)

### What We Test

Real browser interaction with the full stack:

```
1. User navigates to page
   ↓
2. Rails renders Hotwire template (_timeline.html.erb)
   ↓
3. Stimulus controller attaches to DOM
   ↓
4. User clicks expand button
   ↓
5. JavaScript toggles aria-expanded attribute
   ↓
6. CSS shows/hides details section
   ↓
7. Arrow rotates (visual feedback)
```

### Example Test

```ruby
# File: spec/system/timeline_spec.rb

describe 'Timeline System Tests', type: :system do
  let(:status_update) { create(:status_update) }

  it 'user can expand/collapse timeline items' do
    change = create(:status_change,
      status_update: status_update,
      from_status: 'submitted',
      to_status: 'in_review',
      reason: 'Review in progress'
    )
    
    visit status_update_path(status_update)
    
    # Initial state: collapsed
    item = page.find('[data-timeline-item-id]')
    details = item.find('[data-timeline-item-target="details"]')
    expect(details['open']).to be_nil  # Not open
    
    # Click to expand
    item.click
    sleep(0.1)  # Wait for Stimulus to update
    
    # Now expanded
    expect(details['open']).not_to be_nil
    expect(page).to have_content('Review in progress')
    
    # Click to collapse
    item.click
    sleep(0.1)
    
    # Back to collapsed
    expect(details['open']).to be_nil
  end
end
```

### System Test Essentials

**1. Use `driven_by :selenium` for JavaScript**
```ruby
before do
  driven_by :selenium, using: :chrome
end
```

**2. Use `visit` to navigate**
```ruby
visit status_update_path(status_update)
```

**3. Use `page.find` to locate elements**
```ruby
item = page.find('[data-timeline-item-id]')
```

**4. Use `click` for user interaction**
```ruby
item.click
```

**5. Use `sleep` to wait for JavaScript**
```ruby
item.click
sleep(0.1)  # Wait for Stimulus to update
expect(page).to have_content('New content')
```

**6. Test accessibility**
```ruby
expect(page).to have_css('[role="region"]')
expect(page).to have_css('[aria-expanded]')
```

### Why System Tests Matter

- **Real Interaction**: Tests actual browser behavior
- **Catches UI Bugs**: Stimulus controller issues, CSS problems
- **User Perspective**: Tests what users actually do
- **Accessibility**: Verify ARIA attributes, keyboard navigation
- **Integration**: Full stack: HTML + CSS + JavaScript + Rails

---

## 4. Testing the Request-Response Cycle

Here's how we verify data flows correctly through the entire stack:

### Flow: User views timeline

```ruby
# 1. User action
visit status_update_path(status_update)

# 2. Rails renders the template
# (_status_updates/show.html.erb includes _timeline.html.erb)

# 3. Template displays timeline items
# <%= render 'timeline', status_update: @status_update %>

# 4. Template queries database
# status_update.status_changes.ordered

# 5. Template uses data
# <% status_update.status_changes.each do |change| %>
#   <%= change.to_status %>
# <% end %>

# 6. User sees the output
expect(page).to have_content('In Review')
```

### Flow: API request for timeline

```ruby
# 1. Client sends request
get api_v1_status_update_timeline_path(status_update)

# 2. Router matches route
# GET /api/v1/status_updates/:id/timeline

# 3. Controller action runs
def timeline
  @status_update = StatusUpdate.find(params[:id])
  changes = @status_update.status_changes.ordered
  render_data(StatusChangeSerializer.serialize(changes))
end

# 4. Serializer transforms data
# Input:  StatusChange { id: 1, from_status: 'submitted', ... }
# Output: { id: 1, status_display: { to: 'In Review' }, ... }

# 5. JsonResponses wraps in envelope
# Input:  [{ id: 1, ... }]
# Output: { data: [{ id: 1, ... }] }

# 6. HTTP response sent
# Status: 200 OK
# Body: { "data": [{ "id": 1, ... }] }

# 7. Test verifies the output
body = response.parsed_body
expect(body['data'].first['id']).to eq(1)
```

---

## 5. How Enterprise Teams Use Tests

### Pattern 1: Tests as Documentation

```ruby
# Instead of a requirements document, the test IS the spec:

describe 'Timeline API' do
  it 'returns 200 OK for valid status_update' do
    # Clients know: endpoint exists and returns 200
  end
  
  it 'returns 404 for invalid status_update' do
    # Clients know: endpoint validates IDs
  end
  
  it 'returns changes in chronological order' do
    # Clients know: oldest change first
  end
  
  it 'humanizes status labels' do
    # Clients know: 'in_review' becomes 'In Review'
  end
end

# This test file IS the API documentation
```

### Pattern 2: Regression Prevention

```ruby
# Bug found: Status changes were in wrong order
# Fix: Add .ordered scope to query

# Test added to prevent regression:
it 'returns changes in chronological order' do
  create(:status_change, to_status: 'submitted')
  create(:status_change, to_status: 'in_review')
  
  get api_v1_status_update_timeline_path(status_update)
  body = response.parsed_body
  
  expect(body['data'][0]['to_status']).to eq('submitted')
  expect(body['data'][1]['to_status']).to eq('in_review')
end

# Now if someone removes .ordered, this test fails
# The bug can't happen again
```

### Pattern 3: Refactoring Safety

```ruby
# Original code (works):
def timeline
  changes = @status_update.status_changes.order(created_at: :asc)
  serialize_changes(changes)
end

# Run tests: all pass ✅

# Refactor to use scope:
def timeline
  serialize_changes(@status_update.status_changes.ordered)
end

# Run tests: still pass ✅
# We know the refactor is safe

# Delete original code confidently
```

### Pattern 4: Integration Testing

```ruby
# Tests verify components work together:

# Model test: StatusChange.log! works
it 'creates a change record' do
  change = StatusChange.log!(status_update, from: 'submitted', to: 'in_review')
  expect(change).to be_persisted
end

# Controller test: timeline action returns changes
it 'returns all changes' do
  StatusChange.log!(status_update, from: 'submitted', to: 'in_review')
  get api_v1_status_update_timeline_path(status_update)
  expect(response.parsed_body['data'].length).to eq(1)
end

# System test: user can view changes
it 'displays changes in UI' do
  StatusChange.log!(status_update, from: 'submitted', to: 'in_review')
  visit status_update_path(status_update)
  expect(page).to have_content('In Review')
end

# All three layers verify the complete flow works
```

---

## 6. Test Execution

### Run All Timeline Tests

```bash
# Run all tests for timeline feature
rspec spec/models/status_change_spec.rb
rspec spec/requests/api_v1_timeline_spec.rb
rspec spec/system/timeline_spec.rb

# Or run them all at once
rspec spec --pattern "*timeline*"
```

### Run Specific Test

```bash
# Run a single test
rspec spec/requests/api_v1_timeline_spec.rb -e "returns changes in chronological order"

# Run a test group
rspec spec/requests/api_v1_timeline_spec.rb -e "Timeline API"
```

### Generate Coverage Report

```bash
# See what code is tested
rspec spec --format coverage

# We should have 100% coverage on:
# - StatusChange model
# - StatusUpdatesController#timeline action
# - _timeline.html.erb template
# - TimelineItemController stimulus controller
```

---

## 7. Common Testing Patterns

### Pattern: Testing Timestamps

```ruby
# Timestamps need special handling (milliseconds differ)

before do
  @change = create(:status_change)
end

it 'includes ISO8601 timestamp' do
  get api_v1_status_update_timeline_path(status_update)
  body = response.parsed_body
  
  timestamp = body['data'].first['changed_at']
  returned_time = Time.iso8601(timestamp)
  
  # Allow 1 second difference due to rounding
  expect(returned_time).to be_within(1).of(@change.created_at)
end
```

### Pattern: Testing Order

```ruby
# Create records with sleep between them
@change1 = create(:status_change, to_status: 'submitted')
sleep(0.01)
@change2 = create(:status_change, to_status: 'in_review')

# Verify they come back in creation order
get api_v1_status_update_timeline_path(status_update)
body = response.parsed_body

expect(body['data'].first['to_status']).to eq('submitted')
expect(body['data'].last['to_status']).to eq('in_review')
```

### Pattern: Testing User Actions

```ruby
it 'user can expand items' do
  visit status_update_path(status_update)
  
  # Find element
  item = page.find('[data-timeline-item-id]')
  
  # Perform action
  item.click
  
  # Wait for JavaScript
  sleep(0.1)
  
  # Verify result
  details = item.find('[data-timeline-item-target="details"]')
  expect(details['open']).not_to be_nil
end
```

### Pattern: Testing Error Handling

```ruby
it 'returns 404 for missing record' do
  get api_v1_status_update_timeline_path(99999)
  
  expect(response).to have_http_status(:not_found)
  
  body = response.parsed_body
  expect(body).to have_key('error')
  expect(body['error']['code']).to eq('not_found')
end
```

---

## 8. Key Takeaways

### Why Test?

1. **Correctness**: Verify code works as intended
2. **Regression Prevention**: Catch bugs before users do
3. **Documentation**: Tests show what code should do
4. **Refactoring Safety**: Confidently improve code
5. **Integration Verification**: Ensure components work together

### Test Layers (Bottom-Up)

1. **Model Tests**: Fast, isolated, verify business logic
2. **Request Tests**: Verify HTTP API behavior
3. **System Tests**: Verify real browser interaction
4. **(JavaScript Tests)**: Verify JavaScript logic (not yet implemented)

### Best Practices

- **Test behavior, not implementation**
  ```ruby
  # Good: tests what happens
  expect(page).to have_content('In Review')
  
  # Bad: tests how it's done
  expect(page).to have_xpath("//div[@class='status-badge']")
  ```

- **One assertion per test** (when possible)
  ```ruby
  # Good
  it 'returns 200 OK' do
    get api_v1_status_update_timeline_path(status_update)
    expect(response).to have_http_status(:ok)
  end
  
  # Also ok (when related)
  it 'returns 200 with JSON' do
    get api_v1_status_update_timeline_path(status_update)
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include('application/json')
  end
  ```

- **Use descriptive test names**
  ```ruby
  # Good
  it 'returns changes in chronological order (oldest first)'
  
  # Bad
  it 'works'
  ```

- **Set up data clearly**
  ```ruby
  # Good
  before do
    @change1 = create(:status_change, to_status: 'submitted')
    sleep(0.01)
    @change2 = create(:status_change, to_status: 'in_review')
  end
  
  # Bad
  @change1 = create(:status_change)
  @change2 = create(:status_change)
  ```

---

## 9. What's Next?

### JavaScript Tests (Future)

```ruby
# spec/javascript/controllers/timeline_item_controller.test.js

describe('TimelineItemController', () => {
  it('toggles details when summary is clicked', () => {
    // Test Stimulus controller logic directly
  })
  
  it('rotates arrow on toggle', () => {
    // Test CSS class changes
  })
})
```

### Performance Tests (Future)

```ruby
it 'loads timeline within 500ms' do
  start = Time.now
  get api_v1_status_update_timeline_path(status_update)
  elapsed = (Time.now - start) * 1000
  
  expect(elapsed).to be < 500
end
```

### Load Tests (Future)

```ruby
it 'handles 1000 status changes' do
  (0..999).each do |i|
    create(:status_change, status_update: status_update)
  end
  
  get api_v1_status_update_timeline_path(status_update)
  expect(response).to have_http_status(:ok)
end
```

---

## Questions?

The tests in this directory are designed to be **self-documenting**. Read the test name, then read the test code - together they explain what the feature should do and why.

When in doubt, ask: "What is this test verifying?" The answer tells you what the feature does.
