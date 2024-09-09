# frozen_string_literal: true

require "test_helper"
require "minitest/autorun"

class AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @visit1 = hashed_url_visits(:one)
    @visit2 = hashed_url_visits(:two)
    @visit3 = hashed_url_visits(:three)
  end

  test "GET /analytics/url/raw - should return correct analytics data" do
    get "/api/analytics/url/raw"
    assert_response :success

    visits = @response.parsed_body
    raw_data = visits["raw_data"]

    assert_equal HashedUrlVisit.all.as_json, raw_data
  end

  test "GET /analytics/url/raw - should return 500 if there is an internal server error" do
    HashedUrlVisit.stub(:all, -> { raise "Error with ActiveRecord query" }) do
      get "/api/analytics/url/raw"
      assert_response :internal_server_error
      assert_equal "Error with ActiveRecord query", @response.parsed_body["error"]
    end
  end

  test "GET /analytics/url/clicks - should return correct analytics data" do
    get "/api/analytics/url/clicks"
    assert_response :success

    visits = @response.parsed_body
    clicks = visits["clicks"]

    assert_equal HashedUrlVisit.group("hashed_url").count, clicks
  end

  test "GET /analytics/url/clicks - should return 500 if there is an internal server error" do
    HashedUrlVisit.stub(:group, ->(_args) { raise "Error with ActiveRecord query" }) do
      get "/api/analytics/url/clicks"
      assert_response :internal_server_error
      assert_equal "Error with ActiveRecord query", @response.parsed_body["error"]
    end
  end
end
