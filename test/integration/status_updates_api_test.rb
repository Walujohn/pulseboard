require "test_helper"

class StatusUpdatesApiTest < ActionDispatch::IntegrationTest
  setup do
    Comment.delete_all if defined?(Comment)
    StatusUpdate.delete_all
  end


  test "GET /api/v1/status_updates returns list with meta + data" do
    StatusUpdate.create!(body: "First", mood: "focused")
    StatusUpdate.create!(body: "Second", mood: "calm")

    get "/api/v1/status_updates"
    assert_response :success

    json = JSON.parse(response.body)

    assert json["meta"].present?
    assert_equal 1, json["meta"]["page"]
    assert_equal 25, json["meta"]["per_page"]
    assert_equal 2, json["meta"]["total_count"]

    assert json["data"].is_a?(Array)
    assert_equal 2, json["data"].length

    first = json["data"].first
    assert first.key?("id")
    assert first.key?("body")
    assert first.key?("mood")
    assert first.key?("likes_count")
    assert first.key?("created_at")
    assert first.key?("updated_at")
  end

  test "GET /api/v1/status_updates supports pagination" do
    60.times { |i| StatusUpdate.create!(body: "Item #{i}", mood: "focused") }

    get "/api/v1/status_updates", params: { page: 2, per_page: 25 }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 2, json["meta"]["page"]
    assert_equal 25, json["meta"]["per_page"]
    assert_equal 60, json["meta"]["total_count"]
    assert_equal 25, json["data"].length
  end

  test "GET /api/v1/status_updates supports filtering by mood" do
    StatusUpdate.create!(body: "A", mood: "happy")
    StatusUpdate.create!(body: "B", mood: "blocked")

    get "/api/v1/status_updates", params: { mood: "happy" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["meta"]["total_count"]
    assert_equal 1, json["data"].length
    assert_equal "happy", json["data"].first["mood"]
  end

  test "GET /api/v1/status_updates supports query search (q)" do
    StatusUpdate.create!(body: "Appointment scheduled", mood: "focused")
    StatusUpdate.create!(body: "Lunch break", mood: "calm")

    get "/api/v1/status_updates", params: { q: "appoint" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["meta"]["total_count"]
    assert_equal 1, json["data"].length
    assert_match(/Appointment/i, json["data"].first["body"])
  end

  test "POST /api/v1/status_updates creates record and returns data envelope" do
    post "/api/v1/status_updates",
         params: { status_update: { body: "Hello", mood: "happy" } },
         as: :json

    assert_response :created
    json = JSON.parse(response.body)

    assert json["data"].present?
    assert_equal "Hello", json["data"]["body"]
    assert_equal "happy", json["data"]["mood"]
    assert_equal 0, json["data"]["likes_count"]
  end

  test "POST invalid returns 422 with error envelope" do
    post "/api/v1/status_updates",
         params: { status_update: { body: "", mood: "" } },
         as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)

    assert json["error"].present?
    assert_equal "validation_error", json["error"]["code"]
    assert json["error"]["messages"].is_a?(Array)
    assert json["error"]["messages"].any?
  end

  test "GET /api/v1/status_updates/:id returns one item" do
    u = StatusUpdate.create!(body: "One", mood: "calm")

    get "/api/v1/status_updates/#{u.id}"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal u.id, json["data"]["id"]
    assert_equal "One", json["data"]["body"]
  end

  test "PATCH /api/v1/status_updates/:id updates item" do
    u = StatusUpdate.create!(body: "Old", mood: "calm")

    patch "/api/v1/status_updates/#{u.id}",
          params: { status_update: { body: "New" } },
          as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "New", json["data"]["body"]
  end

  test "DELETE /api/v1/status_updates/:id deletes item" do
    u = StatusUpdate.create!(body: "Delete me", mood: "blocked")

    delete "/api/v1/status_updates/#{u.id}"
    assert_response :no_content

    assert_equal 0, StatusUpdate.count
  end
end
