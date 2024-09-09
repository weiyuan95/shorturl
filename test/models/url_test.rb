require "test_helper"

class UrlTest < ActiveSupport::TestCase
  setup do
    @url = urls(:one)
  end

  test "should not be able to create with no params" do
    url = Url.new()
    assert_not url.save
  end

  test "should be able to create only if all params are present" do
    url = Url.new(target_url: "http://abc1234", hashed_url: "1234", salt: "1234", title: "abc")
    assert url.save
  end

  test "should not be able to create if target_url is invalid" do
    url = Url.new(target_url: "abc1234", hashed_url: "1234", salt: "1234", title: "abc")
    assert url.invalid?
    assert_equal "Invalid target_url provided", url.errors.full_messages.first
  end

  test "should correctly generate short_url" do
    url = Url.new(target_url: "http://abc1234", hashed_url: "1234", salt: "1234", title: "abc")
    assert url.save
    # should exist on the created object
    assert_equal "http://localhost:3000/1234", url.short_url
    saved_url = Url.find_by(hashed_url: "1234")
    # and also when fetched from the database
    assert_equal "http://localhost:3000/1234", saved_url.short_url
  end

  test "should not save is hashed_url is not unique" do
    url = Url.new(target_url: "http://abc1234", hashed_url: "1234", salt: "1234", title: "abc")
    # the first save would work
    assert url.save
    new_url = Url.new(target_url: "http://def6789", hashed_url: "1234", salt: "6789", title: "abc")
    # but the second save will fail since the hashed_url is not unique
    assert_not new_url.save
  end

  test "should not save if salt is not unique" do
    url = Url.new(target_url: "http://abc1234", hashed_url: "1234", salt: "1234", title: "abc")
    # the first save would work
    assert url.save
    # but the second save will fail since the salt is not unique
    new_url = Url.new(target_url: "http://def6789", hashed_url: "6789", salt: "1234", title: "abc")
    assert_not new_url.save
  end
end
