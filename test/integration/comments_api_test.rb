require "test_helper"

class CommentsApiTest < ActionDispatch::IntegrationTest
  setup do
    Comment.delete_all if defined?(Comment)
    StatusUpdate.delete_all
  end

  test "GET /api/v1/status_updates/:id/comments returns list with meta + data" do
    status_update = StatusUpdate.create!(body: "Parent", mood: "focused")
    Comment.create!(status_update: status_update, body: "First comment")
    Comment.create!(status_update: status_update, body: "Second comment")

    get "/api/v1/status_updates/#{status_update.id}/comments"
    assert_response :success

    json = JSON.parse(response.body)

    assert json["meta"].present?
    assert_equal 1, json["meta"]["page"]
    assert_equal 25, json["meta"]["per_page"]
    assert_equal 2, json["meta"]["total_count"]

    assert json["data"].is_a?(Array)
    assert_equal 2, json["data"].length

    item = json["data"].first
    assert item.key?("id")
    assert item.key?("status_update_id")
    assert item.key?("body")
    assert item.key?("created_at")
    assert item.key?("updated_at")
  end

  test "GET /api/v1/status_updates/:id/comments supports pagination" do
    status_update = StatusUpdate.create!(body: "Parent", mood: "focused")
    60.times do |i|
      Comment.create!(status_update: status_update, body: "Comment #{i}")
    end

    get "/api/v1/status_updates/#{status_update.id}/comments", params: { page: 2, per_page: 25 }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 2, json["meta"]["page"]
    assert_equal 25, json["meta"]["per_page"]
    assert_equal 60, json["meta"]["total_count"]
    assert_equal 25, json["data"].length
  end

  test "POST /api/v1/status_updates/:id/comments creates comment and returns data envelope" do
    status_update = StatusUpdate.create!(body: "Parent", mood: "calm")

    post "/api/v1/status_updates/#{status_update.id}/comments",
         params: { comment: { body: "New comment" } },
         as: :json

    assert_response :created
    json = JSON.parse(response.body)

    assert json["data"].present?
    assert_equal "New comment", json["data"]["body"]
    assert_equal status_update.id, json["data"]["status_update_id"]
    assert json["data"]["id"].present?
  end

  test "POST /api/v1/status_updates/:id/comments with invalid input returns 422 error envelope" do
    status_update = StatusUpdate.create!(body: "Parent", mood: "calm")

    post "/api/v1/status_updates/#{status_update.id}/comments",
         params: { comment: { body: "" } },
         as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)

    assert json["error"].present?
    assert_equal "validation_error", json["error"]["code"]
    assert json["error"]["messages"].is_a?(Array)
    assert json["error"]["messages"].any?
  end

  test "GET /api/v1/status_updates/:id/comments returns 404 for missing parent" do
    get "/api/v1/status_updates/999999/comments"
    assert_response :not_found
  end

  test "GET /api/v1/status_updates/:id/comments supports query search (q)" do
    status_update = StatusUpdate.create!(body: "Parent", mood: "focused")
    Comment.create!(status_update: status_update, body: "Appointment scheduled")
    Comment.create!(status_update: status_update, body: "Lunch break")

    get "/api/v1/status_updates/#{status_update.id}/comments", params: { q: "appoint" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["meta"]["total_count"]
    assert_equal 1, json["data"].length
    assert_match(/Appointment/i, json["data"].first["body"])
  end

  test "GET /api/v1/status_updates/:id/comments supports since filter (ISO8601)" do
    status_update = StatusUpdate.create!(body: "Parent", mood: "focused")

    old_comment = Comment.create!(status_update: status_update, body: "Old")
    old_comment.update_column(:created_at, 2.days.ago)

    new_comment = Comment.create!(status_update: status_update, body: "New")
    new_comment.update_column(:created_at, Time.current)

    get "/api/v1/status_updates/#{status_update.id}/comments", params: { since: 1.day.ago.iso8601 }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json["meta"]["total_count"]
    assert_equal 1, json["data"].length
    assert_equal "New", json["data"].first["body"]
  end
end
