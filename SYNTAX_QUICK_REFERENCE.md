# Syntax Quick Reference Guide

Quick lookup for Ruby, Rails, JavaScript, and Testing syntax you'll encounter daily.

---

## RUBY BASICS

### Variables & Data Types

```ruby
# Strings
name = "John"                    # Double quotes (can interpolate)
greeting = 'Hello'               # Single quotes (literal)
text = "Hello, #{name}!"         # Interpolation with #{}

# Numbers
count = 42                        # Integer
price = 19.99                     # Float
large = 1_000_000                 # Underscores for readability

# Arrays
colors = ["red", "blue"]          # List of items
numbers = [1, 2, 3, 4]
colors << "green"                 # Add to end
colors.push("yellow")             # Same as <<
first = colors[0]                 # Access by index (0-based)
colors.length                      # => 4

# Hashes (like JavaScript objects)
person = { name: "John", age: 30 }         # Symbol keys (preferred)
person = { "name" => "John", "age" => 30 } # String keys (old style)
person[:name]                               # Access with :symbol
person["age"]                               # Access with "string"
person.keys                                 # => [:name, :age]
person.values                               # => ["John", 30]

# Symbols (lightweight strings, often used as keys)
:status                           # Symbol
:status == :status                # => true
```

### Methods (Functions)

```ruby
# Simple method
def greet(name)
  "Hello, #{name}!"
end
greet("Alice")                    # => "Hello, Alice!"

# Method with default value
def greeting(name = "World")
  "Hello, #{name}!"
end

# Method with multiple return values (returns array)
def get_coordinates
  [10, 20]
end
x, y = get_coordinates            # x=10, y=20 (destructuring)

# Method with keyword arguments
def create_user(name:, email:, admin: false)
  # name and email required, admin optional
end
create_user(name: "John", email: "john@example.com")
create_user(name: "Jane", email: "jane@example.com", admin: true)

# Method with splat (*args) - accepts multiple arguments
def add(*numbers)
  numbers.sum
end
add(1, 2, 3, 4)                   # => 10

# Method with block (&block)
def with_logging(&block)
  puts "Starting..."
  block.call                      # Execute the block
  puts "Done!"
end
with_logging { puts "Doing something" }

# Return value (last line returned automatically)
def calculate
  5 + 3                           # This is returned (no return keyword needed)
end
```

### Control Flow

```ruby
# if/elsif/else
if age >= 18
  "Adult"
elsif age >= 13
  "Teenager"
else
  "Child"
end

# Ternary operator (one-liner if/else)
status = age >= 18 ? "Adult" : "Child"

# unless (opposite of if)
puts "Not logged in" unless user.logged_in?
# Same as: if !user.logged_in?

# case/when (switch)
case user.role
when "admin"
  "Full access"
when "editor"
  "Can edit"
when "viewer"
  "Read only"
else
  "No access"
end

# Loops
(1..5).each { |i| puts i }        # => 1, 2, 3, 4, 5
[1, 2, 3].each { |num| puts num }
array.map { |x| x * 2 }           # Transform each element
array.select { |x| x > 5 }        # Filter elements
array.find { |x| x > 5 }          # Return first match
```

### Strings

```ruby
"hello".upcase                    # => "HELLO"
"HELLO".downcase                  # => "hello"
"hello world".capitalize          # => "Hello world"
"hello".length                    # => 5
"hello".include?("ll")            # => true (ends with ?)
"hello".start_with?("he")         # => true
"hello".end_with?("lo")           # => true
"hello world".split(" ")          # => ["hello", "world"]
" hello ".strip                   # => "hello" (remove whitespace)
"hello".reverse                   # => "olleh"
"hello" + " world"                # => "hello world"
```

### Classes & Objects

```ruby
class User
  # Class variable
  @@count = 0
  
  # Instance variable (exists on each object)
  attr_accessor :name               # Creates name getter/setter
  attr_reader :id                   # Only getter
  attr_writer :password             # Only setter
  
  # Constructor
  def initialize(name, email)
    @name = name                    # Instance variable
    @email = email
    @@count += 1
  end
  
  # Instance method
  def full_name
    @name
  end
  
  # Class method (called on class, not instance)
  def self.count
    @@count
  end
  
  # Private method (can't call from outside)
  private
  
  def validate_email
    # Only callable from inside this class
  end
end

user = User.new("John", "john@example.com")
user.name                         # => "John"
User.count                        # => 1 (class method)
```

---

## RAILS SYNTAX

### Models

```ruby
class User < ApplicationRecord
  # Associations
  has_many :posts                    # User has many posts
  has_many :comments, through: :posts
  belongs_to :company                # User belongs to one company
  has_one :profile
  
  # Validations
  validates :email, presence: true
  validates :email, uniqueness: true
  validates :age, inclusion: { in: 18..120 }
  validates :password, length: { minimum: 8 }
  validates :name, presence: true, length: { minimum: 2 }
  
  # Callbacks (run at certain times)
  before_save :normalize_email
  after_create :send_welcome_email
  before_destroy :archive_data
  
  # Scopes (reusable queries)
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :adults, -> { where("age >= 18") }
  
  # Custom method
  def full_name
    "#{first_name} #{last_name}"
  end
  
  private
  
  def normalize_email
    self.email = email.downcase
  end
  
  def send_welcome_email
    # Send email logic
  end
end

# Using scopes
User.active                       # All active users
User.active.recent                # Active users, newest first
User.where(age: 18..30)           # Users aged 18-30
User.find(1)                      # Find by ID
User.find_by(email: "john@example.com")  # Find by attribute
User.all                          # All users
```

### Controllers

```ruby
class UsersController < ApplicationController
  # before_action runs a method before specified actions
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  
  # GET /users - List all
  def index
    @users = User.all
    render :index                 # Renders app/views/users/index.html.erb
  end
  
  # GET /users/1 - Show one
  def show
    # @user already set by set_user
  end
  
  # POST /users - Create
  def create
    @user = User.new(user_params)
    if @user.save
      render json: { data: @user }, status: :created
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /users/1 - Update
  def update
    if @user.update(user_params)
      render json: { data: @user }
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end
  
  # DELETE /users/1 - Delete
  def destroy
    @user.destroy
    render json: { message: "User deleted" }
  end
  
  private
  
  # Strong parameters (whitelist what can be updated)
  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
  
  # Before action helper
  def set_user
    @user = User.find(params[:id])
  end
end
```

### Routes

```ruby
# config/routes.rb

Rails.application.routes.draw do
  # RESTful routes (create 7 routes automatically)
  resources :users            # GET /users, POST /users, GET /users/1, etc.
  
  # Namespaced routes (API)
  namespace :api do
    namespace :v1 do
      resources :users        # GET /api/v1/users
      resources :posts        # GET /api/v1/posts
    end
  end
  
  # Custom route
  get '/about', to: 'pages#about'
  post '/contact', to: 'pages#create_contact'
  
  # Member routes (routes with ID)
  resources :users do
    member do
      post :send_email        # POST /users/1/send_email
    end
  end
  
  # Collection routes (routes without ID)
  resources :posts do
    collection do
      get :published          # GET /posts/published
    end
  end
end
```

### Database Migrations

```ruby
# db/migrate/20260118_create_users.rb

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    # Create table
    create_table :users do |t|
      t.string :name                    # VARCHAR
      t.string :email
      t.text :bio                       # TEXT (longer)
      t.integer :age                    # INT
      t.boolean :active, default: true  # BOOLEAN
      t.datetime :last_login            # TIMESTAMP
      t.timestamps                      # created_at, updated_at
    end
    
    # Add index for performance
    add_index :users, :email, unique: true
  end
end

# Running migrations
# rails db:migrate           # Run new migrations
# rails db:rollback         # Undo last migration
# rails db:reset            # Drop, create, migrate
```

### Serializers

```ruby
class UserSerializer
  def initialize(user)
    @user = user
  end
  
  def as_json(options = {})
    {
      id: @user.id,
      name: @user.name,
      email: @user.email,
      posts: @user.posts.map { |p| PostSerializer.new(p).as_json }
    }
  end
end

# Usage in controller
@users = User.all
render json: @users.map { |u| UserSerializer.new(u).as_json }
```

---

## JAVASCRIPT / REACT SYNTAX

### Variables & Data Types

```javascript
// var (old, avoid it)
var x = 5

// let (mutable, block-scoped)
let name = "John"
name = "Jane"               // Can reassign

// const (immutable reference, prefer this)
const age = 30
// age = 31                 // ERROR - can't reassign
const arr = [1, 2, 3]
arr.push(4)                 // OK - can modify contents

// Strings
const greeting = "Hello"
const message = `Hello, ${name}!`    // Template literal with ${}
const multiline = `Line 1
Line 2`

// Numbers
const count = 42
const decimal = 3.14
const total = 1_000_000

// Arrays
const colors = ["red", "blue", "green"]
colors[0]                   // => "red"
colors.push("yellow")
colors.length               // => 4
colors.map(c => c.toUpperCase())
colors.filter(c => c.length > 3)

// Objects
const person = {
  name: "John",
  age: 30,
  email: "john@example.com"
}
person.name                 // => "John"
person["age"]               // => 30

// Destructuring (extract properties)
const { name, age } = person
// Now: name = "John", age = 30

const [first, second] = colors
// Now: first = "red", second = "blue"
```

### Functions

```javascript
// Function declaration
function add(a, b) {
  return a + b
}

// Arrow function (modern, preferred)
const multiply = (a, b) => {
  return a * b
}

// Arrow function shorthand (one-liner)
const double = x => x * 2
const greet = () => "Hello"

// Default parameters
const greeting = (name = "World") => `Hello, ${name}!`

// Rest parameters (...args)
const sum = (...numbers) => numbers.reduce((a, b) => a + b, 0)
sum(1, 2, 3, 4)             // => 10

// Callback function
const processData = (data, callback) => {
  const result = data * 2
  callback(result)
}
processData(5, (result) => console.log(result))  // => 10

// Promise
const fetchUser = (id) => {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (id > 0) {
        resolve({ id, name: "John" })
      } else {
        reject("Invalid ID")
      }
    }, 1000)
  })
}

// Async/await (cleaner promise syntax)
const getUser = async (id) => {
  try {
    const user = await fetchUser(id)
    console.log(user)
  } catch (error) {
    console.error(error)
  }
}
```

### React Components & Hooks

```javascript
// Simple component (function)
function Welcome({ name }) {
  return <h1>Hello, {name}!</h1>
}

// Component with state
function Counter() {
  const [count, setCount] = useState(0)
  
  const increment = () => setCount(count + 1)
  
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={increment}>+1</button>
    </div>
  )
}

// Effect hook (run code after render)
useEffect(() => {
  console.log("Component mounted")
  
  return () => {
    console.log("Component unmounting - cleanup")
  }
}, [])  // Empty deps = run once on mount

// Effect with dependencies
useEffect(() => {
  console.log("userId changed:", userId)
  // Fetch user data...
}, [userId])  // Run when userId changes

// useContext (share data across components)
const ThemeContext = createContext()

function App() {
  return (
    <ThemeContext.Provider value={{ mode: 'dark' }}>
      <Header />
    </ThemeContext.Provider>
  )
}

function Header() {
  const theme = useContext(ThemeContext)
  return <div>Mode: {theme.mode}</div>
}

// useReducer (complex state)
const reducer = (state, action) => {
  switch (action.type) {
    case 'INCREMENT':
      return { count: state.count + 1 }
    case 'DECREMENT':
      return { count: state.count - 1 }
    default:
      return state
  }
}

function Calculator() {
  const [state, dispatch] = useReducer(reducer, { count: 0 })
  
  return (
    <div>
      <p>{state.count}</p>
      <button onClick={() => dispatch({ type: 'INCREMENT' })}>+</button>
    </div>
  )
}
```

### JSX (JavaScript + HTML)

```javascript
// Conditional rendering
{isLoggedIn && <Dashboard />}
{isLoggedIn ? <Dashboard /> : <LoginForm />}

// Lists
{users.map(user => (
  <div key={user.id}>
    <h3>{user.name}</h3>
  </div>
))}

// Event handling
<button onClick={() => handleClick()}>Click me</button>
<input onChange={(e) => setName(e.target.value)} />
<form onSubmit={(e) => {
  e.preventDefault()
  handleSubmit()
}}>

// CSS classes
<div className="container">
  <p className={isActive ? "active" : "inactive"}>Text</p>
</div>

// Inline styles
<div style={{ color: 'red', fontSize: '16px' }}>Styled text</div>

// Comments in JSX
{/* This is a comment */}
```

---

## TESTING SYNTAX (RSpec)

### Basic RSpec Structure

```ruby
# spec/models/user_spec.rb

RSpec.describe User, type: :model do
  # Setup before each test
  before(:each) do
    @user = User.create(name: "John", email: "john@example.com")
  end
  
  describe "Associations" do
    it "has many posts" do
      expect(@user).to have_many(:posts)
    end
  end
  
  describe "Validations" do
    it "requires email" do
      user = User.new(name: "John")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end
    
    it "requires unique email" do
      User.create(email: "john@example.com")
      duplicate = User.new(email: "john@example.com")
      expect(duplicate).not_to be_valid
    end
  end
  
  describe "#full_name" do
    it "combines first and last name" do
      user = User.new(first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end
  end
  
  describe "Scopes" do
    it ".active returns only active users" do
      User.create(name: "Active", active: true)
      User.create(name: "Inactive", active: false)
      
      expect(User.active.count).to eq(1)
    end
  end
end
```

### Request Specs (API Testing)

```ruby
# spec/requests/api_v1_users_spec.rb

RSpec.describe "GET /api/v1/users", type: :request do
  before do
    @user = User.create(name: "John", email: "john@example.com")
  end
  
  it "returns list of users" do
    get "/api/v1/users"
    
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to match(a_string_including("application/json"))
    
    data = JSON.parse(response.body)
    expect(data["data"]).to be_an(Array)
    expect(data["data"][0]["name"]).to eq("John")
  end
  
  it "filters by email" do
    get "/api/v1/users", params: { email: "john@example.com" }
    
    expect(response).to have_http_status(:ok)
    data = JSON.parse(response.body)
    expect(data["data"].count).to eq(1)
  end
  
  it "handles pagination" do
    5.times { |i| User.create(name: "User #{i}", email: "user#{i}@example.com") }
    
    get "/api/v1/users", params: { page: 1, per_page: 2 }
    
    data = JSON.parse(response.body)
    expect(data["data"].count).to eq(2)
    expect(data["meta"]["page"]).to eq(1)
    expect(data["meta"]["total_count"]).to eq(6)
  end
end

RSpec.describe "POST /api/v1/users", type: :request do
  it "creates a user" do
    expect {
      post "/api/v1/users", params: {
        user: { name: "Jane", email: "jane@example.com" }
      }
    }.to change(User, :count).by(1)
    
    expect(response).to have_http_status(:created)
  end
  
  it "returns validation errors" do
    post "/api/v1/users", params: { user: { name: "John" } }
    
    expect(response).to have_http_status(:unprocessable_entity)
    data = JSON.parse(response.body)
    expect(data["errors"]).to be_present
  end
end
```

### Shared Examples (DRY Testing)

```ruby
RSpec.shared_examples "an API response" do
  it "returns JSON" do
    expect(response.content_type).to match(a_string_including("application/json"))
  end
  
  it "has expected structure" do
    data = JSON.parse(response.body)
    expect(data).to have_key("data")
  end
end

RSpec.describe "GET /api/v1/users", type: :request do
  before { get "/api/v1/users" }
  
  include_examples "an API response"
end
```

### Common RSpec Matchers

```ruby
# Equality
expect(5).to eq(5)                      # Exact equality
expect("hello").to eql("hello")
expect([1, 2]).to match_array([2, 1])   # Same elements, any order

# Truthiness
expect(true).to be_truthy
expect(false).to be_falsy
expect(nil).to be_nil
expect(5).to be_present
expect(nil).to be_blank

# Comparisons
expect(5).to be > 3
expect(5).to be < 10
expect(5).to be >= 5
expect(5).to be <= 5

# Inclusion
expect([1, 2, 3]).to include(2)
expect("hello").to include("ll")
expect({ a: 1 }).to have_key(:a)
expect({ a: 1 }).to have_value(1)

# Type checking
expect(5).to be_an(Integer)
expect([]).to be_an(Array)
expect({}).to be_a(Hash)

# Collections
expect([1, 2, 3]).to have_length(3)
expect("hello").to have_length(5)
expect(array).to be_empty
expect(array).not_to be_empty

# Strings
expect("hello").to start_with("he")
expect("hello").to end_with("lo")
expect("hello").to match(/ell/)

# Database
expect { User.create }.to change(User, :count).by(1)
expect { user.destroy }.to change(User, :count).by(-1)
expect(user).to be_valid
expect(user).not_to be_valid

# Model associations
expect(user).to have_many(:posts)
expect(post).to belong_to(:user)

# Rails model validations
expect(user).to validate_presence_of(:email)
expect(user).to validate_uniqueness_of(:email)
```

### Factories (Mock Data) - COMPREHENSIVE GUIDE

**What are factories?** They create realistic test data without writing boilerplate in every test.

```ruby
# spec/factories.rb - Define test data builders

FactoryBot.define do
  # Basic factory
  factory :user do
    name { "John Doe" }                    # Use {} for dynamic values
    email { "john#{rand(1000)}@example.com" }  # Different each time
    password { "password123" }
    active { true }
  end
  
  # Factory with association
  factory :post do
    user                                   # Automatically creates associated user
    title { "My Post" }
    content { "Post content..." }
    published_at { Time.current }
  end
  
  # Factory with sequence (auto-increment unique values)
  factory :comment do
    post
    user
    content { "Comment #{sequence(:number)}" }  # Comment 1, Comment 2, etc.
  end
  
  # Factory with traits (variations)
  factory :user do
    name { "John Doe" }
    email { "john@example.com" }
    password { "password123" }
    
    # Trait: admin user
    trait :admin do
      role { "admin" }
    end
    
    # Trait: inactive user
    trait :inactive do
      active { false }
    end
  end
  
  # Inheritance (post_with_comments has all post attributes + comments)
  factory :post_with_comments, parent: :post do
    after(:create) do |post, evaluator|
      create_list(:comment, 3, post: post)
    end
  end
end

# ===== USAGE IN TESTS =====

# Create (saves to database)
user = create(:user)                    # => User instance with id, saved
post = create(:post)                    # => Post instance with associated user

# Build (doesn't save to database)
user = build(:user)                     # => User instance without id
expect(user).not_to be_persisted        # => true

# Create_list (multiple at once)
users = create_list(:user, 3)           # => Array of 3 users
expect(users.length).to eq(3)

# Build_list
users = build_list(:user, 5)            # => Array of 5 unsaved users

# Override attributes
user = create(:user, name: "Jane", email: "jane@example.com")
expect(user.name).to eq("Jane")

# Use traits
admin = create(:user, :admin)           # User with role: "admin"
inactive_admin = create(:user, :admin, :inactive)  # Multiple traits

# Create with associations
post = create(:post, user: create(:user, name: "Alice"))
expect(post.user.name).to eq("Alice")

# Create related data
post = create(:post_with_comments)      # Post with 3 comments auto-created
expect(post.comments.count).to eq(3)

# Attributes hash (don't save, use for testing new instances)
attrs = attributes_for(:user)           # => { name: "...", email: "...", ... }
user = User.new(attrs)
expect(user).to be_valid
```

**Why use factories?**
- ✅ Less code in tests (no repetitive `User.create(...)`)
- ✅ Realistic data (sequences, associations work automatically)
- ✅ Easy to modify (change default, use traits)
- ✅ Consistent test data (same structure every time)
- ✅ Database transactions (safe cleanup between tests)

**Real-world example from your codebase:**

```ruby
# spec/factories.rb

FactoryBot.define do
  factory :status_update do
    title { "Status update #{sequence(:number)}" }
    content { "Updated status..." }
    user                                  # Assumes has_one or belongs_to user
    status { "active" }
    created_at { Time.current }
  end
  
  factory :comment do
    status_update
    user
    content { "Great update!" }
    created_at { Time.current }
  end
  
  factory :reaction do
    status_update
    user
    reaction_type { "like" }
  end
  
  factory :status_change do
    status_update
    old_status { "pending" }
    new_status { "active" }
  end
end

# In your tests
RSpec.describe StatusUpdate do
  let(:status_update) { create(:status_update) }
  let(:comments) { create_list(:comment, 3, status_update: status_update) }
  
  it "has many comments" do
    expect(status_update.comments.count).to eq(3)
  end
end
```

**Common factory methods:**

```ruby
create(:user)                           # Save to database
build(:user)                            # Don't save
create_list(:user, 5)                   # Create 5 and save
build_list(:user, 5)                    # Build 5, don't save
attributes_for(:user)                   # Hash of attributes only
stub(:user)                             # Minimal stub object

# Callbacks (run custom code)
factory :user do
  after(:create) do |user|
    # Run after user is created
    user.send_welcome_email
  end
  
  before(:build) do |user|
    # Run before user is built
    user.validate
  end
end
```

---

## FIXTURES & MINITEST (Legacy Rails Testing)

**Will you encounter these?** Maybe. Older Rails projects and legacy code use fixtures + minitest. Your current project uses RSpec, but government projects often have older code.

### Fixtures (Test Data Files)

Fixtures are YAML files that define test data (older way than factories).

```yaml
# test/fixtures/users.yml

john:
  name: John Doe
  email: john@example.com
  password: password123
  active: true

jane:
  name: Jane Smith
  email: jane@example.com
  password: password123
  active: false

inactive_user:
  name: Bob
  email: bob@example.com
  active: false
```

```ruby
# test/models/user_test.rb - Using fixtures

class UserTest < ActiveSupport::TestCase
  # Fixtures automatically loaded - available as methods
  
  test "john fixture exists" do
    assert users(:john).present?
    assert_equal "john@example.com", users(:john).email
  end
  
  test "fixtures can be referenced by symbol" do
    user = users(:john)
    assert_equal "John Doe", user.name
  end
  
  test "fixture associations work" do
    # If post fixture has user_id: john's id
    post = posts(:johns_first_post)
    assert_equal users(:john), post.user
  end
end
```

**Fixtures vs Factories:**

| Fixture | Factory |
|---------|---------|
| YAML files (static) | Ruby code (dynamic) |
| Loaded once per test file | Created fresh per test |
| Hard to modify per test | Easy to override attributes |
| Older Rails projects | Modern Rails projects (RSpec) |
| Must remember fixture names | Self-documenting code |

**Fixture associations:**

```yaml
# test/fixtures/posts.yml

johns_post:
  title: John's First Post
  user: john                    # Reference to john fixture
  content: Some content

janes_post:
  title: Jane's Post
  user: jane
  content: Other content

# test/fixtures/comments.yml

johns_comment:
  post: johns_post              # Chain associations
  user: john
  content: Great post!
```

---

## MINITEST SYNTAX

Minitest is Rails' default testing framework (older than RSpec). You might see this in legacy projects.

### Basic Minitest Tests

```ruby
# test/models/user_test.rb

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Setup runs before each test
  setup do
    @user = users(:john)        # Use fixture
  end
  
  # Teardown runs after each test
  teardown do
    # Cleanup if needed
  end
  
  # Test method (must start with 'test_')
  test "should have valid email" do
    assert @user.email.present?
  end
  
  test "should not be valid without name" do
    @user.name = nil
    assert_not @user.valid?
  end
  
  test "email should be unique" do
    duplicate = @user.dup
    @user.save
    assert_not duplicate.valid?
  end
end
```

### Minitest Assertions (like RSpec matchers)

```ruby
# Equality
assert_equal 5, 2 + 3
assert_not_equal 5, 3

# Truthiness
assert true
assert_not false
assert_nil nil
assert_not_nil value
assert_empty array
assert_not_empty array

# Comparisons
assert value > 5
assert value < 10

# Inclusion
assert [1, 2, 3].include?(2)
assert_includes [1, 2, 3], 2
assert string.include?("substring")

# Type checking
assert value.is_a?(Integer)
assert value.is_a?(String)

# Strings
assert string.start_with?("Hello")
assert string.end_with?("World")
assert string.match?(/pattern/)

# Raises error
assert_raises(CustomError) do
  some_failing_code
end

# Database changes
assert_difference('User.count', 1) do
  User.create(name: "John")
end

assert_difference('User.count', -1) do
  user.destroy
end

# Model validations
assert user.valid?
assert_not user.valid?
assert user.errors[:email].present?
```

### Minitest Request Tests

```ruby
# test/controllers/users_controller_test.rb

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
  end
  
  test "should get index" do
    get users_url
    assert_response :success
  end
  
  test "should show user" do
    get user_url(@user)
    assert_response :success
    assert_select "h1", "John Doe"    # CSS selector for HTML content
  end
  
  test "should create user" do
    assert_difference('User.count') do
      post users_url, params: { user: { name: "Jane", email: "jane@example.com" } }
    end
    assert_redirected_to user_url(User.last)
  end
  
  test "should update user" do
    patch user_url(@user), params: { user: { name: "John Smith" } }
    assert_redirected_to user_url(@user)
    @user.reload
    assert_equal "John Smith", @user.name
  end
  
  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete user_url(@user)
    end
    assert_redirected_to users_url
  end
end
```

### Minitest vs RSpec Comparison

```ruby
# ===== RSPEC (What you're using) =====
RSpec.describe User do
  before(:each) do
    @user = create(:user)
  end
  
  it "requires email" do
    user = User.new(name: "John")
    expect(user).not_to be_valid
  end
end

# ===== MINITEST (Legacy Rails) =====
class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:john)
  end
  
  test "requires email" do
    user = User.new(name: "John")
    assert_not user.valid?
  end
end
```

**Key differences:**
- RSpec: `describe`, `it`, `expect(...).to`, factories
- Minitest: `test`, `assert`, `assert_not`, fixtures

---

## SHOULD YOU LEARN MINITEST?

**Short answer:** Not now, but good to recognize.

**When to learn minitest:**
- ✅ You're asked to work on a legacy Rails project (pre-2015)
- ✅ Company standardized on minitest instead of RSpec
- ✅ You encounter it and need to fix tests

**For now:**
- ✅ Stick with RSpec (what you know)
- ✅ Recognize minitest syntax when you see it
- ✅ Know that `test` = `it` and `assert_equal` = `expect(...).to eq`

**At USCIS/Government:**
- 🤷 Could be either (older = more likely minitest)
- 📖 But switching between them is easy once you know one framework

---

## QUICK FIXTURE/MINITEST PATTERNS

```ruby
# Pattern 1: Load fixture data
test "user has valid attributes" do
  user = users(:john)           # Load from fixture
  assert_equal "john@example.com", user.email
end

# Pattern 2: Create fixture-based associations
test "post belongs to user" do
  post = posts(:johns_post)     # Fixture that references john
  assert_equal users(:john), post.user
end

# Pattern 3: Difference assertions
test "creates new user" do
  assert_difference('User.count', 1) do
    User.create!(name: "New", email: "new@example.com")
  end
end

# Pattern 4: HTML assertions (controller tests)
test "renders user name in HTML" do
  get user_url(@user)
  assert_select "h1", @user.name  # CSS selector
end

# Pattern 5: Redirect assertions
test "creates and redirects" do
  post users_url, params: { user: { name: "Test" } }
  assert_redirected_to user_url(User.last)
end
```

**When you see fixtures/minitest in the wild:**
1. Look for `.yml` files in `test/fixtures/`
2. Look for `test/` folder instead of `spec/` folder
3. Look for `assert_` instead of `expect`
4. Look for `class YourTest < ActiveSupport::TestCase`

---



### Basic Jest Tests

```javascript
// src/utils.test.js

describe('Math utilities', () => {
  it('adds two numbers', () => {
    const result = add(2, 3)
    expect(result).toBe(5)
  })
  
  it('subtracts two numbers', () => {
    const result = subtract(5, 3)
    expect(result).toBe(2)
  })
})

// Setup/teardown
describe('Database operations', () => {
  beforeEach(() => {
    // Runs before each test
    setupDatabase()
  })
  
  afterEach(() => {
    // Runs after each test
    cleanupDatabase()
  })
  
  beforeAll(() => {
    // Runs once before all tests
    initializeConnection()
  })
  
  afterAll(() => {
    // Runs once after all tests
    closeConnection()
  })
})
```

### Testing React Components

```javascript
// src/Counter.test.js
import { render, screen, fireEvent } from '@testing-library/react'
import Counter from './Counter'

describe('Counter component', () => {
  it('displays initial count of 0', () => {
    render(<Counter />)
    
    const count = screen.getByText('Count: 0')
    expect(count).toBeInTheDocument()
  })
  
  it('increments count when button clicked', () => {
    render(<Counter />)
    
    const button = screen.getByRole('button', { name: /\+1/i })
    fireEvent.click(button)
    
    expect(screen.getByText('Count: 1')).toBeInTheDocument()
  })
  
  it('finds elements by test ID', () => {
    render(<Counter />)
    
    const counter = screen.getByTestId('counter-display')
    expect(counter).toBeInTheDocument()
  })
})
```

### Common Jest Matchers

```javascript
// Equality
expect(5).toBe(5)
expect({ a: 1 }).toEqual({ a: 1 })
expect("hello").toMatch(/ell/)

// Truthiness
expect(true).toBeTruthy()
expect(false).toBeFalsy()
expect(null).toBeNull()
expect(undefined).toBeUndefined()

// Numbers
expect(5).toBeGreaterThan(3)
expect(5).toBeGreaterThanOrEqual(5)
expect(5).toBeLessThan(10)
expect(0.1 + 0.2).toBeCloseTo(0.3)

// Strings
expect("hello").toMatch(/ell/)
expect("hello").toMatch("ell")

// Arrays/Objects
expect([1, 2, 3]).toContain(2)
expect({ a: 1, b: 2 }).toHaveProperty('a')
expect({ a: 1 }).toHaveProperty('a', 1)

// Errors
expect(() => {
  throw new Error('test error')
}).toThrow()
expect(() => {
  throw new Error('test error')
}).toThrow('test error')

// DOM
expect(element).toBeInTheDocument()
expect(input).toHaveValue('text')
expect(button).toBeDisabled()
expect(element).toHaveClass('active')

// Mocks
expect(mockFunction).toHaveBeenCalled()
expect(mockFunction).toHaveBeenCalledWith('arg1', 'arg2')
expect(mockFunction).toHaveBeenCalledTimes(3)
```

---

## COMMON PATTERNS CHEAT SHEET

### Rails API Response Pattern

```ruby
# Controller
def index
  @users = User.all
  render json: {
    data: @users.map { |u| UserSerializer.new(u).as_json },
    meta: { total_count: User.count, page: 1 }
  }
end

# Test
get "/api/v1/users"
expect(response).to have_http_status(:ok)
data = JSON.parse(response.body)
expect(data["data"]).to be_an(Array)
```

### React Form Pattern

```javascript
const [formData, setFormData] = useState({
  name: '',
  email: ''
})

const handleChange = (e) => {
  const { name, value } = e.target
  setFormData(prev => ({
    ...prev,
    [name]: value
  }))
}

const handleSubmit = async (e) => {
  e.preventDefault()
  await fetch('/api/users', {
    method: 'POST',
    body: JSON.stringify(formData)
  })
}

return (
  <form onSubmit={handleSubmit}>
    <input name="name" value={formData.name} onChange={handleChange} />
    <input name="email" value={formData.email} onChange={handleChange} />
    <button type="submit">Submit</button>
  </form>
)
```

### Data Fetching Pattern

```ruby
# Rails
def index
  @data = fetch_from_external_api
  render json: { data: @data }
end

private

def fetch_from_external_api
  response = Net::HTTP.get_response(URI("https://api.example.com/data"))
  JSON.parse(response.body)
end
```

```javascript
// JavaScript
useEffect(() => {
  const fetchData = async () => {
    try {
      const response = await fetch('/api/data')
      const json = await response.json()
      setData(json.data)
    } catch (error) {
      setError(error.message)
    }
  }
  
  fetchData()
}, [])
```

---

## QUICK LOOKUP BY USE CASE

### "How do I create something?"
- Rails Model: `rails generate model User name:string email:string`
- Rails Controller: `rails generate controller Users`
- React Component: `function MyComponent() { return <div></div> }`
- Array: `[1, 2, 3]` (Ruby) or `[1, 2, 3]` (JavaScript)
- Hash: `{ name: "John" }` (Ruby) or `{ name: "John" }` (JavaScript)

### "How do I check if something exists?"
- Ruby: `user.present?`, `array.any?`, `hash.key?(:name)`
- JavaScript: `value !== null`, `array.length > 0`, `object.hasOwnProperty('name')`
- Database: `User.exists?(id: 1)` (Ruby), `count > 0` (SQL)

### "How do I loop through something?"
- Ruby: `.each`, `.map`, `.select`, `.find`
- JavaScript: `.forEach()`, `.map()`, `.filter()`, `.find()`
- Rails: `<% @users.each do |user| %> ... <% end %>`
- React: `{users.map(user => <div key={user.id}>{user.name}</div>)}`

### "How do I handle errors?"
- Ruby: `begin...rescue...ensure`
- JavaScript: `try...catch...finally`
- Tests: `expect { action }.to raise_error` (Ruby), `expect(() => action).toThrow()` (JavaScript)

### "How do I test something?"
- Models: `RSpec.describe User, type: :model`
- Controllers: `RSpec.describe "GET /api/v1/users", type: :request`
- Components: `render(<MyComponent />)` with `@testing-library/react`
- API: Check `response.status`, `response.body`, `JSON.parse(response.body)`

---

That's your syntax quick reference! Bookmark this when you need a fast lookup. 🚀
