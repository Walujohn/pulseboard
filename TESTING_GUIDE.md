# Testing Quick Reference Guide

This document provides example patterns for writing tests in Pulseboard using RSpec, Capybara, and Factory Bot.

## Model Tests with Shoulda Matchers

### Validation Tests
```ruby
describe 'validations' do
  # Presence validation
  it { should validate_presence_of(:body) }
  
  # Length validation
  it { should validate_length_of(:body).is_at_most(280) }
  
  # Inclusion validation (enum-like)
  it { should validate_inclusion_of(:mood).in_array(StatusUpdate::MOODS) }
end
```

### Association Tests
```ruby
describe 'associations' do
  # has_many
  it { should have_many(:comments).dependent(:destroy) }
  
  # belongs_to
  it { should belong_to(:status_update) }
end
```

## Instance Method Tests

```ruby
describe '#increment_likes' do
  let(:status_update) { create(:status_update, likes_count: 5) }

  it 'increments the likes count' do
    expect {
      status_update.increment_likes
    }.to change(status_update, :likes_count).from(5).to(6)
  end

  it 'persists the change to the database' do
    status_update.increment_likes
    expect(StatusUpdate.find(status_update.id).likes_count).to eq(6)
  end
end
```

## Scope Tests

```ruby
describe '.recent scope' do
  it 'returns records ordered by created_at descending' do
    su1 = create(:status_update, body: 'Oldest')
    su2 = create(:status_update, body: 'Newest')
    
    # Important: Use .where() to isolate your test records
    recent = StatusUpdate.where(id: [su1.id, su2.id]).recent
    expect(recent.first.id).to eq(su2.id)
  end
end
```

## Factory Bot Patterns

### Basic Factory Definition
```ruby
FactoryBot.define do
  factory :status_update do
    body { Faker::Lorem.sentence }
    mood { StatusUpdate::MOODS.sample }
    likes_count { 0 }
  end
end
```

### Using Factories in Tests
```ruby
# Create a single record
status_update = create(:status_update)

# Create with overrides
status_update = create(:status_update, body: 'Custom body', mood: 'happy')

# Build (doesn't save)
status_update = build(:status_update)

# Create a list
updates = create_list(:status_update, 5)
```

## System Tests (Integration Tests) with Capybara

### Basic Flow Test
```ruby
describe 'Creating a status update' do
  it 'creates a new status update and displays it' do
    # Visit the page
    visit root_path
    
    # Fill in form fields
    fill_in 'Mood', with: 'happy'
    fill_in 'Body', with: 'Feeling great today!'
    
    # Click button
    click_button 'Post update'
    
    # Assert results
    expect(page).to have_content('Feeling great today!')
    expect(page).to have_content('😊 Happy')
  end
end
```

### Testing Validations
```ruby
it 'displays validation errors when fields are missing' do
  visit root_path
  click_button 'Post update'
  
  expect(page).to have_content("can't be blank")
end

it 'displays error when body exceeds character limit' do
  visit root_path
  fill_in 'Mood', with: 'focused'
  fill_in 'Body', with: 'a' * 281
  click_button 'Post update'
  
  expect(page).to have_content('is too long')
end
```

### Testing AJAX/Turbo Interactions
```ruby
it 'increments like count via AJAX' do
  visit root_path
  
  expect(page).to have_content('0')
  click_button '👍'
  
  # Turbo updates the DOM without page reload
  expect(page).to have_content('1')
end
```

### Testing Confirmations
```ruby
it 'deletes the status update after confirmation' do
  visit root_path
  
  accept_confirm do
    click_button 'Delete'
  end
  
  expect(page).not_to have_content('Delete me')
end
```

### Testing Collections
```ruby
it 'displays comments in reverse chronological order' do
  comment1 = create(:comment, body: 'First', created_at: 2.hours.ago)
  comment2 = create(:comment, body: 'Second', created_at: 1.hour.ago)
  
  visit root_path
  
  comments = page.all('.comment__body').map(&:text)
  expect(comments.first).to include('Second')
  expect(comments.last).to include('First')
end
```

### Scoping Elements
```ruby
# within() scopes actions to a specific element
within first('.comments-section') do
  fill_in 'Add a comment:', with: 'Nice post!'
  click_button 'Post Comment'
end

expect(page).to have_content('Nice post!')
```

## Request/API Tests

```ruby
describe 'GET /api/v1/status_updates/:id/comments' do
  let(:status_update) { create(:status_update) }
  let!(:comment) { create(:comment, status_update: status_update) }

  it 'returns all comments for a status update' do
    get api_v1_status_update_comments_path(status_update)
    
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['data'].length).to eq(1)
  end
end

describe 'POST /api/v1/status_updates/:id/comments' do
  let(:status_update) { create(:status_update) }

  it 'creates a comment' do
    post api_v1_status_update_comments_path(status_update), 
      params: { comment: { body: 'Great post!' } }
    
    expect(response).to have_http_status(:created)
    expect(response.parsed_body['data']['body']).to eq('Great post!')
  end

  it 'returns validation errors' do
    post api_v1_status_update_comments_path(status_update), 
      params: { comment: { body: '' } }
    
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body['error']['messages']).to include("Body can't be blank")
  end
end
```

## Common Assertions

```ruby
# Content
expect(page).to have_content('text')
expect(page).not_to have_content('text')

# Elements
expect(page).to have_button('Submit')
expect(page).to have_link('Edit')
expect(page).to have_field('Name')

# Status codes
expect(response).to have_http_status(:ok)
expect(response).to have_http_status(:created)
expect(response).to have_http_status(:unprocessable_entity)

# Collections
expect(array).to include(item)
expect(array.length).to eq(3)

# JSON responses
expect(response.parsed_body['data']).to be_present
expect(response.parsed_body['error']).to include('message')
```

## Tips & Best Practices

1. **Use `create()` for integration tests, `build()` for unit tests**
   - Integration tests need persisted data
   - Unit tests don't need database writes

2. **Isolate your test records**
   - Use `.where(id: [record.id])` to isolate scope tests from fixtures

3. **Use semantic CSS classes in views**
   - Makes Capybara tests more robust
   - Better maintainability

4. **Use `let()` for setup, `let!()` for side effects**
   - `let()` is lazy-evaluated
   - `let!()` is eagerly-evaluated and persists

5. **Group related tests with `describe` blocks**
   - Better organization
   - Clearer test intent

6. **Use factories consistently**
   - Define once, use everywhere
   - Overrides for specific test cases

7. **Test user behavior, not implementation**
   - Click buttons, fill forms
   - Assert visible results
   - Don't test internal code paths

8. **Keep tests simple and focused**
   - One assertion per test (where possible)
   - Clear test names that describe behavior
   - Avoid complex setup logic

## Running Tests

```bash
# All RSpec tests
bundle exec rspec

# Specific test file
bundle exec rspec spec/models/status_update_spec.rb

# Specific test
bundle exec rspec spec/models/status_update_spec.rb:50

# With output formatting
bundle exec rspec --format documentation
bundle exec rspec --format progress

# Watch for changes (with appropriate gem)
bundle exec rspec --format progress spec/

# Random order (helps find hidden dependencies)
bundle exec rspec --order random

# Rails default tests
bundle exec rails test
```

## Debugging Tests

```ruby
# Print to console
puts object.inspect
p object  # shorthand

# Use pry for breakpoints (if pry-rails gem installed)
binding.pry  # or binding.irb in newer Rails

# Check what's on the page
save_and_open_page  # requires launchy gem

# Get visible text
puts page.text

# Get HTML
puts page.html
```
