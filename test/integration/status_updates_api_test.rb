require "test_helper"

class StatusUpdatesApiTest < ActionDispatch::IntegrationTest
  setup do
    StatusUpdate.delete_all
  end

  test "GET /api/v1/status_updates returns list" do
    StatusUpdate.create!(body: "First", mood: "focused")
    StatusUpdate.create!(body: "Second", mood: "calm")

    get "/api/v1/status_updates"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 2, json.length
    assert json.first.key?("id")
    assert json.first.key?("body")
    assert json.first.key?("mood")
    assert json.first.key?("likes_count")
  end

  test "POST /api/v1/status_updates creates record" do
    post "/api/v1/status_updates",
         params: { status_update: { body: "Hello", mood: "happy" } },
         as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Hello", json["body"]
    assert_equal "happy", json["mood"]
  end

  test "POST invalid returns 422 with errors" do
    post "/api/v1/status_updates",
         params: { status_update: { body: "", mood: "" } },
         as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].present?
  end
end
