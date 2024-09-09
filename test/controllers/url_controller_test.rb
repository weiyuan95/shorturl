require "test_helper"
require "minitest/autorun"

class UrlControllerTest < ActionDispatch::IntegrationTest
  setup do
    @existing_url = urls(:one)
  end

  test "GET /:hash - should return 302 and correct redirect_url if :hash has been saved" do
    # Ensure that the visit has been saved
    assert_difference("HashedUrlVisit.count") do
      get "/#{@existing_url[:hashed_url]}"
      assert_response :moved_permanently
      assert_equal @existing_url.target_url, @response.redirect_url
    end

    saved_visit = HashedUrlVisit.last
    assert_equal @existing_url[:hashed_url], saved_visit[:hashed_url]
    assert_equal "Unknown", saved_visit[:country]
  end

  test "GET /:hash - should return 404 if :hash is not present" do
    get "/non_existent_hash"
    assert_response :not_found
  end

  test "GET /url/:hash - should return 404 if :hash is not present" do
    get "/api/url"
    assert_response :not_found
  end

  test "GET /url/:hash - should return saved url if :hash exists" do
    get "/api/url/#{@existing_url[:hashed_url]}"

    assert_response :success
    url = @response.parsed_body

    assert_equal @existing_url[:target_url], url[:target_url]
    assert_equal @existing_url[:title], url[:title]
    assert_equal @existing_url[:hashed_url], url[:hashed_url]
  end

  test "POST /url - should return 422 when target_url is not in request body" do
    post "/api/url"
    assert_response :unprocessable_content
  end

  test "POST /url - should return 422 when target_url is invalid" do
    post "/api/url", params: { target_url: "http:///abc.com" }, as: :json
    assert_response :unprocessable_content
  end

  test "POST /url - should return 500 when failed to hash target_url" do
    # The only possibility for this error to be thrown is if we hit a hash_collision 20 times in a row,
    # which is _extremely_ unlikely.
    # We can stub the salt to be the same as the existing url in the fixture to force a hash collision.
    SecureRandom.stub :uuid_v4, @existing_url.salt do
      post "/api/url", params: { target_url: @existing_url.target_url }, as: :json
      assert_response :internal_server_error
    end
  end
end
