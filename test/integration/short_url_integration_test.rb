# frozen_string_literal: true

require "minitest/autorun"
require "test_helper"

# These suite of tests are testing flows from a user's perspective. Unhappy cases can be found in the individual
# controller tests.
class ShortUrlIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # We do not want the fixture data for our integration test - it should be a clean slate of data
    hashed_url_visits.each(&:destroy)
  end

  test "GET /:hash - should return 302 and correct redirect_url if shortening is successful with correct analytics" do
    target_url = "https://blog.weiyuan.dev"
    post "/api/url", params: { target_url: target_url }, as: :json
    assert_response :success

    saved_url = @response.parsed_body
    assert_equal target_url, saved_url[:target_url]
    assert_equal "http://localhost:3000/#{saved_url[:hashed_url]}", saved_url[:short_url]

    # Ensure that the visit has been saved
    get "/#{saved_url[:hashed_url]}"
    assert_response :moved_permanently
    assert_equal target_url, @response.redirect_url

    get "/api/analytics/url/raw"
    assert_response :success
    analytics_raw_data = @response.parsed_body["raw_data"]

    get "/api/analytics/url/clicks"
    assert_response :success

    analytics_clicks = @response.parsed_body["clicks"]

    assert_equal 1, analytics_raw_data.size
    assert_equal 1, analytics_clicks.size
    assert_equal 1, analytics_clicks[saved_url[:hashed_url]]
    assert_equal "Unknown", analytics_raw_data.first["country"]
    assert_equal saved_url[:hashed_url], analytics_raw_data.first["hashed_url"]
  end

  test "POST /url - should successfully create a new url when target_url is in request body and is valid" do
    # Note: We need to use values that are not already in our fixtures, if not this test will fail
    stubbed_uuid = "f1c3cc0d-5af9-4cd5-a0e4-4d25252f04a0"
    target_url = "https://blog.weiyuan.dev"
    # the expected hash based on the stubbed_uuid and target_url
    expected_hash = "25wEWwkr"
    expected_title = "Wei Yuan's Blog"

    SecureRandom.stub :uuid_v4, stubbed_uuid do
      # Given a target_url
      # When we shorten it
      assert_difference("Url.count") do
        post "/api/url", params: { target_url: target_url }, as: :json
        assert_response :success
      end

      saved_url = @response.parsed_body
      # Then the values should be correctly in the response
      assert_equal target_url, saved_url[:target_url]
      assert_equal expected_hash, saved_url[:hashed_url]
      assert_equal stubbed_uuid, saved_url[:salt]
      assert_equal expected_title, saved_url[:title]
      assert_equal "http://localhost:3000/#{expected_hash}", saved_url[:short_url]

      # When we query for it with the previously saved hashed_url
      get "/api/url/#{saved_url[:hashed_url]}"
      assert_response :success
      retrieved_url = @response.parsed_body

      # Then the values should have been correctly saved and returned
      assert_equal target_url, retrieved_url[:target_url]
      assert_equal expected_title, retrieved_url[:title]
      assert_equal expected_hash, retrieved_url[:hashed_url]
      assert_equal "http://localhost:3000/#{expected_hash}", retrieved_url[:short_url]
    end
  end
end
