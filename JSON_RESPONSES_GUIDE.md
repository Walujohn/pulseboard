# JsonResponses Concern Usage Guide

## Overview

The `JsonResponses` concern provides a consistent, DRY way to render JSON responses across all API controllers. It's located at `app/controllers/api/v1/json_responses.rb`.

## How to Use

### 1. Include the Concern in Your Controller

```ruby
module Api
  module V1
    class MyResourceController < ActionController::API
      include JsonResponses
      
      # ... controller code
    end
  end
end
```

## Available Methods

### `render_data(data, status)`

Use for successful responses with data.

**Parameters:**
- `data` - The data to return (serialized or plain)
- `status` - HTTP status code (`:ok`, `:created`, etc.)

**Example:**
```ruby
def show
  update = StatusUpdate.find(params[:id])
  render_data(serialize_one(update), :ok)
end

# Renders:
# { "data": { "id": 1, "body": "...", ... } }
```

### `render_error(code, message, status)`

Use for error responses.

**Parameters:**
- `code` - Error code (e.g., `"not_found"`, `"invalid_request"`)
- `message` - Human-readable error message
- `status` - HTTP status code

**Example:**
```ruby
def show
  user = User.find(params[:id])
rescue ActiveRecord::RecordNotFound
  render_error("not_found", "User not found", :not_found)
end

# Renders:
# { "error": { "code": "not_found", "message": "User not found" } }
```

### `render_validation_errors(record, status)`

Use for ActiveRecord validation failures.

**Parameters:**
- `record` - The AR model with validation errors
- `status` - HTTP status code (usually `:unprocessable_entity`)

**Example:**
```ruby
def create
  user = User.new(user_params)
  if user.save
    render_data(serialize_one(user), :created)
  else
    render_validation_errors(user, :unprocessable_entity)
  end
end

# Renders on error:
# { 
#   "error": { 
#     "code": "validation_error", 
#     "messages": ["Email can't be blank", "Name is too short"]
#   } 
# }
```

### `render_paginated_data(items, meta, status)`

Use for list responses with pagination metadata.

**Parameters:**
- `items` - Array of serialized items
- `meta` - Hash with pagination info (page, per_page, total_count)
- `status` - HTTP status code

**Example:**
```ruby
def index
  scope = StatusUpdate.order(created_at: :desc)
  total_count = scope.count
  items = paginate(scope)  # from Paginatable concern

  render_paginated_data(
    serialize_many(items),
    {
      page: page_param,
      per_page: per_page_param,
      total_count: total_count
    },
    :ok
  )
end

# Renders:
# {
#   "meta": {
#     "page": 1,
#     "per_page": 10,
#     "total_count": 42
#   },
#   "data": [{ "id": 1, ... }, { "id": 2, ... }]
# }
```

### `serialize_one(record)`

Helper to serialize a single record using the appropriate serializer.

**Supported Models:**
- `StatusUpdate` → uses `StatusUpdateSerializer`
- `StatusChange` → uses `StatusChangeSerializer`
- `Comment` → uses `CommentSerializer`
- `Reaction` → uses `ReactionSerializer`

**Example:**
```ruby
update = StatusUpdate.find(params[:id])
render_data(serialize_one(update), :ok)
```

### `serialize_many(records)`

Helper to serialize an array of records.

**Example:**
```ruby
changes = status_update.status_changes.ordered
render_data(serialize_many(changes), :ok)
```

## Error Codes

Recommended error codes for consistency:

| Code | Usage | Status |
|------|-------|--------|
| `not_found` | Resource doesn't exist | 404 |
| `validation_error` | ActiveRecord validations failed | 422 |
| `unauthorized` | Authentication required | 401 |
| `forbidden` | Authorization failed | 403 |
| `invalid_request` | Malformed request | 400 |

## Response Format

All responses follow a consistent envelope pattern:

### Success Response
```json
{
  "data": { /* serialized data */ }
}
```

### Error Response
```json
{
  "error": {
    "code": "error_code",
    "message": "Human-readable message"
  }
}
```

### Validation Error Response
```json
{
  "error": {
    "code": "validation_error",
    "messages": ["Field can't be blank", "Field is too long"]
  }
}
```

### Paginated Response
```json
{
  "meta": {
    "page": 1,
    "per_page": 10,
    "total_count": 42
  },
  "data": [/* array of items */]
}
```

## Common Patterns

### Create with Validation
```ruby
def create
  resource = Resource.new(resource_params)
  
  if resource.save
    render_data(serialize_one(resource), :created)
  else
    render_validation_errors(resource, :unprocessable_entity)
  end
end
```

### Show with Not Found
```ruby
def show
  resource = Resource.find(params[:id])
  render_data(serialize_one(resource), :ok)
rescue ActiveRecord::RecordNotFound
  render_error("not_found", "Resource not found", :not_found)
end
```

### List with Filtering and Pagination
```ruby
def index
  scope = Resource.order(created_at: :desc)
  
  # Filtering
  scope = scope.where(status: params[:status]) if params[:status].present?
  
  # Pagination
  total_count = scope.count
  items = paginate(scope)
  
  render_paginated_data(
    serialize_many(items),
    {
      page: page_param,
      per_page: per_page_param,
      total_count: total_count
    },
    :ok
  )
end
```

## Adding New Serializers

When you add a new model that needs JSON serialization:

1. Create the serializer: `app/serializers/model_serializer.rb`
2. Add a case in `serialize_one`:
   ```ruby
   def serialize_one(record)
     case record
     when StatusUpdate
       StatusUpdateSerializer.new(record).as_json
     when YourModel
       YourModelSerializer.new(record).as_json
     else
       record
     end
   end
   ```
3. Update `serialize_many` if it dispatches to `serialize_one` (which it should)

## Testing

When testing API endpoints, expect the response envelope format:

```ruby
it 'returns paginated comments' do
  status_update = create(:status_update)
  create(:comment, status_update: status_update)
  
  get api_v1_status_update_comments_path(status_update)
  
  expect(response).to have_http_status(:ok)
  
  body = response.parsed_body
  expect(body).to have_key('meta')
  expect(body).to have_key('data')
  expect(body['meta']).to include('page', 'per_page', 'total_count')
  expect(body['data']).to be_an(Array)
end
```

## Benefits

✅ **Consistency**: All API responses follow identical pattern
✅ **DRY**: No duplication of response rendering logic
✅ **Maintainability**: Change format in one place, applies everywhere
✅ **Clarity**: Response structure is clear and predictable
✅ **Testability**: Easy to test API responses
✅ **Standards**: Follows REST API best practices
✅ **Scalability**: Easy to add new endpoints with correct format

## See Also

- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Detailed refactoring changes
- [REFACTORING_COMPLETE.md](REFACTORING_COMPLETE.md) - Test results and validation
- [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md) - System design overview
