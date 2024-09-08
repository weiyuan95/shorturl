# This class acts as a 'soft' interface since ruby is not a statically typed language.
# When this is extended to a class, the class is expected to implement the hash_function method.
class UrlHasher
  # @param [String] target_url
  # @return [HashedUrl::Url] A data class containing the hashed_url, target_url, and salt.
  def self.hash_url(target_url)
    self.validate(target_url)
    hashed_url, salt = self.hash_function(target_url)
    HashedUrl::Url.new(hashed_url: hashed_url, target_url: target_url, salt: salt)
  end

  # Takes in a target_url and raises an ArgumentError if the target_url is invalid.
  # A target_url is considered valid if it is a valid URI and it has a host (http or https).
  # This is a best effort at validating the target_url, and is not probably not exhaustive. The
  # best method to validate a URL is to make a request (eg. `get url`) to it, however, that introduces some overhead.
  # @param [String] target_url
  def self.validate(target_url)
    uri = URI.parse(target_url)
    unless uri.host.present?
      raise ArgumentError, "Invalid target_url provided"
    end
  rescue URI::InvalidURIError
    raise ArgumentError, "Invalid target_url provided"
  end

  # Takes in a target_url and returns an array containing [hashed_url, salt].
  # The implementation is up to the developer when extending this class, however:
  # - The output should be deterministic and unique.
  # - The resultant hash should be no longer than 8 characters.
  # - A random salt must be used to modify target_url before hashing to guarantee uniqueness
  # @param [String] target_url
  # @return [[string, string]] An array containing [hashed_url, salt].
  def self.hash_function(target_url)
    raise NotImplementedError, "hash_function must be implemented"
  end
end
