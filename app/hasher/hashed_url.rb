# frozen_string_literal: true

module HashedUrl
  class Url < Data.define(:hashed_url, :target_url, :salt)
  end
end
