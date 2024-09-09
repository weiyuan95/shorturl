# frozen_string_literal: true

module HashedUrl
  class Url
    attr_reader :hashed_url, :target_url, :salt

    def initialize(hashed_url:, target_url:, salt:)
      @hashed_url = hashed_url
      @target_url = target_url
      @salt = salt
    end
  end
end
