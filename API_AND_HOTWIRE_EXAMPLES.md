# Reactions Feature: Rails API + React vs. Hotwire Examples

This document explains the Reactions feature implementation showing two different approaches:
1. **React Frontend** - Traditional SPA approach with separate API
2. **Hotwire** - Rails-centric approach with Stimulus + Turbo

## Overview

The Reactions feature allows users to react to status updates with emoji reactions (👍, ❤️, 😂, 😮, 😢, 🔥).

Both implementations have the exact same functionality but very different architectures.

## Database Structure

```
Reaction Model:
- id: integer (primary key)
- status_update_id: integer (foreign key)
- emoji: string (validated against EMOJIS constant)
- user_identifier: string (session/user ID)
- created_at: timestamp
- updated_at: timestamp

Validations:
- emoji must be in Reaction::EMOJIS
- user_identifier is required
- user can only react once per emoji per status update (uniqueness constraint)
```

## Rails API Endpoints

### GET /api/v1/status_updates/:status_update_id/reactions

Returns grouped reactions with emoji, count, and list of users.

**Response:**
```json
{
  "data": [
    {
      "emoji": "👍",
      "count": 3,
      "users": ["user_1", "user_2", "user_3"]
    },
    {
      "emoji": "❤️",
      "count": 1,
      "users": ["user_5"]
    }
  ]
}
```

### POST /api/v1/status_updates/:status_update_id/reactions

Creates a reaction (or toggles it if it already exists).

**Request:**
```json
{
  "reaction": {
    "emoji": "👍",
    "user_identifier": "user_123"
  }
}
```

**Response (created):**
```json
{
  "data": {
    "id": 1,
    "emoji": "👍",
    "user_identifier": "user_123",
    "status_update_id": 42,
    "created_at": "2026-01-14T22:50:00Z"
  }
}
```

**Response (toggle - already exists):**
```json
{
  "data": {
    "toggled": false
  }
}
```

## Approach 1: React Frontend

**Files:**
- `app/javascript/components/ReactionPicker.jsx` - React component
- Rails API endpoints (same for both approaches)

### Architecture

```
┌─────────────────────────────────────────┐
│        React Component                   │
│  (ReactionPicker.jsx)                   │
│                                         │
│  ├─ useState: reactions, loading        │
│  ├─ useEffect: fetch on mount           │
│  └─ handleReactionClick: POST request   │
└────────────────────┬────────────────────┘
                     │
                     ↓
          ┌──────────────────────┐
          │  Rails API (JSON)    │
          │  ReactionsController │
          └──────────────────────┘
                     │
                     ↓
          ┌──────────────────────┐
          │    Database          │
          │   (Reactions)        │
          └──────────────────────┘
```

### Key Concepts

**State Management:**
```javascript
const [reactions, setReactions] = useState([]);
const [loading, setLoading] = useState(true);
const [error, setError] = useState(null);
```

**Side Effects (Data Fetching):**
```javascript
useEffect(() => {
  fetchReactions();
}, [statusUpdateId]);
```

**API Calls:**
```javascript
const response = await fetch(
  `/api/v1/status_updates/${statusUpdateId}/reactions`,
  {
    method: 'POST',
    headers: { ... },
    body: JSON.stringify({ reaction: { emoji, user_identifier } })
  }
);
```

**Event Handling:**
```javascript
const handleReactionClick = async (emoji) => {
  // Make API call
  // Update state
  // Component re-renders
}
```

### Advantages

✅ Rich interactive UI  
✅ Instant feedback (optimistic updates possible)  
✅ Works well for complex interactions  
✅ Separates frontend and backend  
✅ Reusable component library  
✅ Scales to large applications  

### Disadvantages

❌ Requires JavaScript framework  
❌ More code to maintain  
❌ SEO challenges (content in JavaScript)  
❌ Complexity: state management, hooks, lifecycle  
❌ Bundle size  
❌ Build step required  

## Approach 2: Hotwire (Stimulus + Turbo)

**Files:**
- `app/javascript/controllers/reactions_controller.js` - Stimulus controller
- `app/views/reactions/_display.html.erb` - Server-rendered HTML
- Same Rails API endpoints (can also use web controllers instead)

### Architecture

```
┌──────────────────────────────────────┐
│  Server-Rendered HTML (from Rails)   │
│  + Stimulus Controller Enhancement   │
│  (reactions_controller.js)           │
│                                      │
│  ├─ toggleReaction: POST request     │
│  └─ refreshReactions: fetch + update │
└────────────────────┬─────────────────┘
                     │
                     ↓
          ┌──────────────────────┐
          │  Rails API (JSON)    │
          │  ReactionsController │
          └──────────────────────┘
                     │
                     ↓
          ┌──────────────────────┐
          │    Database          │
          │   (Reactions)        │
          └──────────────────────┘
```

### Key Concepts

**No Client-Side State:**
```javascript
// State lives in database, not JavaScript
// Server renders the current state to HTML
```

**Data Attributes (Server → Stimulus):**
```erb
<div data-controller="reactions"
     data-reactions-status-update-id-value="<%= @status_update.id %>"
     data-reactions-user-id-value="<%= session_user_id %>">
```

**Simple Event Handling:**
```html
<button data-action="reactions#toggleReaction"
        data-emoji="👍">
  👍
</button>
```

**Fetching Updates:**
```javascript
async toggleReaction(event) {
  const response = await fetch(
    `/api/v1/status_updates/${this.statusUpdateIdValue}/reactions`,
    { method: 'POST', ... }
  );
  await this.refreshReactions();
}
```

### Advantages

✅ Less JavaScript  
✅ Works without JavaScript (HTML form fallback)  
✅ Better SEO (content in HTML)  
✅ Server handles state (simpler, more secure)  
✅ Easier CSRF protection  
✅ No build step  
✅ Smaller bundle  
✅ Easier to understand for Rails developers  

### Disadvantages

❌ Less flexible for complex UIs  
❌ Server round-trips for updates  
❌ Requires re-rendering HTML fragments  
❌ Slower perceived performance (can use optimistic updates)  

## Converting React to Hotwire

If you had a React component and wanted to convert it to Hotwire, here's the mapping:

```
React Component        → Stimulus Controller + Server HTML
├─ useState           → Database/Server State
├─ useEffect          → Server-rendered on load
├─ handleClick        → data-action="controller#method"
├─ fetch POST         → Stimulus controller method
└─ setState/re-render → refreshReactions() or Turbo streams
```

### Step-by-Step Conversion

**1. Move State to Server**
```javascript
// REACT
const [reactions, setReactions] = useState([]);

// HOTWIRE
<!-- Server renders -->
<%= render "reactions/display", reactions: @status_update.reactions %>
```

**2. Add Stimulus Controller**
```javascript
// REACT
const handleReactionClick = async (emoji) => { ... }

// HOTWIRE
export default class extends Controller {
  async toggleReaction(event) { ... }
}
```

**3. Add Event Bindings in HTML**
```erb
<!-- REACT: onClick={handleReactionClick} handled in JS -->

<!-- HOTWIRE: Declarative in HTML -->
<button data-action="reactions#toggleReaction"
        data-emoji="<%= emoji %>">
  <%= emoji %>
</button>
```

**4. Update DOM via Fetch + DOM Manipulation or Turbo**
```javascript
// REACT: setState triggers re-render

// HOTWIRE: Fetch + manual DOM update or Turbo stream
async toggleReaction(event) {
  await fetch(...)
  await this.refreshReactions() // Updates DOM
}
```

## Best Practices for Each Approach

### React Best Practices

✅ Use hooks for side effects (useEffect, useCallback)  
✅ Separate API logic into services  
✅ Use custom hooks to reuse logic  
✅ Implement error boundaries  
✅ Use lazy loading for code splitting  
✅ Handle loading and error states  
✅ Prop validation with PropTypes or TypeScript  

```javascript
// Good: Custom hook for API calls
const useReactions = (statusUpdateId) => {
  const [reactions, setReactions] = useState([]);
  
  useEffect(() => {
    fetchReactions(statusUpdateId).then(setReactions);
  }, [statusUpdateId]);
  
  return reactions;
};
```

### Hotwire Best Practices

✅ Use data attributes for configuration  
✅ Keep Stimulus controllers focused  
✅ Use Turbo streams for complex updates  
✅ Provide HTML form fallback  
✅ Use ActionCable for real-time updates  
✅ Cache server responses when possible  
✅ Test with and without JavaScript enabled  

```javascript
// Good: Focused, single-responsibility controller
export default class extends Controller {
  static targets = ["reactionsDisplay"];
  
  async toggleReaction(event) {
    // One method, one responsibility
  }
}
```

## Testing Both Approaches

### React Testing
```javascript
// With React Testing Library
test('adds reaction when emoji clicked', async () => {
  render(<ReactionPicker statusUpdateId={1} userId="user_1" />);
  
  const button = screen.getByRole('button', { name: '👍' });
  fireEvent.click(button);
  
  await waitFor(() => {
    expect(screen.getByText('1')).toBeInTheDocument();
  });
});
```

### Hotwire Testing
```ruby
# With RSpec + Capybara
describe 'Reactions', type: :system do
  it 'adds reaction when emoji clicked' do
    visit status_update_path(@status_update)
    
    click_button '👍'
    
    expect(page).to have_content('1')
  end
end
```

## Which Approach to Choose?

**Use React when:**
- Building a complex, interactive application
- You have a dedicated frontend team
- You need offline capabilities (with service workers)
- You're building a mobile app (with React Native)
- You need rich animations and transitions

**Use Hotwire when:**
- Building Rails applications with simple to moderate interactivity
- You want to maximize developer velocity
- SEO is important
- You prefer keeping logic in one language (Ruby)
- You want minimal JavaScript maintenance
- You're retrofitting interactivity to existing Rails views

## Performance Comparison

```
                React                 Hotwire
───────────────────────────────────────────────
Initial Load     ~ 2-3 sec            ~ 0.5-1 sec
                 (JS bundle size)     (minimal JS)

Click Reaction   ~ 200-300ms          ~ 400-600ms
                 (optimistic update)  (round-trip)

Code Size        ~ 50KB+ (minified)   ~ 5-10KB

SEO              Limited              Excellent
                 (JS rendered)        (HTML native)

Development      Faster (once setup)  Fastest
Time             (after learning)     (Rails idioms)
```

## Real-World Example

A production app might:
1. Use **Hotwire for core features** (comments, reactions, basic interactions)
2. Use **React for complex features** (real-time collaboration, rich editor)
3. Use **ActionCable for real-time updates** (new comments, reactions)

This gives you the best of both worlds!

## Summary

Both approaches work perfectly. The Reactions feature demonstrates:

- **Rails API** → Endpoints for JSON data
- **React** → Client-side state management, complex UX
- **Hotwire** → Server-centric, simpler, leaner code

The key insight: the same Rails API can power both React and Hotwire frontends. Choose based on your project needs!
