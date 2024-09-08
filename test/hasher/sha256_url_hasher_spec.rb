# frozen_string_literal: true

require "minitest/autorun"
require "test_helper"

describe "Sha256UrlHasher" do
  it "should successfully hash a url deterministically" do
    # Stub the uuid method to return a deterministic value
    # uuidv4 generated from https://www.uuidgenerator.net/version4
    SecureRandom.stub :uuid_v4, "c82eb535-29e5-48b1-a293-bc68a11df464" do
      url = Sha256UrlHasher.hash_url("https://www.google.com")
      assert_equal url.hashed_url, "2DUT5byy"
      assert_equal url.hashed_url.length, 8
    end

    # When we run it again, the hashed_url should be the same (ie. it's deterministic())
    SecureRandom.stub :uuid_v4, "c82eb535-29e5-48b1-a293-bc68a11df464" do
      url = Sha256UrlHasher.hash_url("https://www.google.com")
      assert_equal url.hashed_url, "2DUT5byy"
      assert_equal url.hashed_url.length, 8
    end
  end

  it "should throw a RuntimeException when too many retries are attempted" do
    Url.stub :find_by_hashed_url, true do
      err = assert_raises(RuntimeError) { Sha256UrlHasher.hash_url("https://www.google.com") }
      assert_equal "Too many hashing attempts retries", err.message
    end
  end

  it "should be able to generate different hashes for the same target_url" do
    url1 = Sha256UrlHasher.hash_url("https://www.google.com")
    url2 = Sha256UrlHasher.hash_url("https://www.google.com")
    assert_not_equal url1.hashed_url, url2.hashed_url
  end

  [ nil, "", "invalid_url", "http:/abc.com", "http:///abc.com", "abc.com", "abc123", true, false ].each do |invalid_url|
    it "should raise an ArgumentError when hashing an invalid target_url ->#{invalid_url}" do
      # intentionally pass in different types to ensure that the error is properly raised
      err = assert_raises(ArgumentError) { Sha256UrlHasher.hash_url(invalid_url) }
      assert_equal "Invalid target_url provided", err.message
    end
  end

  %w[
    http://abc.com
    https://abc.com
    http://www.abc.com
    https://www.abc.com
    http://abc.org
    http://abc.org/foo/bar
    http://abc.com?foo=bar&baz=zaz
  ].each do |valid_url|
    it "should successfully hash a valid url ->#{valid_url}" do
      url = Sha256UrlHasher.hash_url(valid_url)
      # we only assert the length of the hashed_url since the actual value is random based on the
      # randomly generated uuid. Given the hash function and our URLs at test, it should at least be 6 characters long.
      assert_operator url.hashed_url.length, :>=, 6
    end
  end
end
