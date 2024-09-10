require "test_helper"
require "minitest/autorun"

class UrlControllerTest < ActionDispatch::IntegrationTest
  setup do
    @existing_url = urls(:one)
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
    assert_equal "http://localhost:3000/#{@existing_url[:hashed_url]}", url[:short_url]
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
        saved_url = @response.parsed_body
        # Then the values should be correctly in the response
        assert_equal target_url, saved_url[:target_url]
        assert_equal expected_hash, saved_url[:hashed_url]
        assert_equal stubbed_uuid, saved_url[:salt]
        assert_equal expected_title, saved_url[:title]
        assert_equal "http://localhost:3000/#{expected_hash}", saved_url[:short_url]
      end
    end
  end
end
