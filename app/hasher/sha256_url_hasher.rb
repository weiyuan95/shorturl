# frozen_string_literal: true

class Sha256UrlHasher < UrlHasher
  def self.hash_function(target_url)
    # HASHING LOGIC
    # Generate a uuidv4 salt
    # Prepend it to the front of a `target_url`
    # `hash = SHA256_hash(#{salt}#{target_url})`
    # if `base62encode(hash[0..10])` exists, re-hash and re-encode with a different `salt`
    # if it does not exist, we have a valid hash to return
    def self.attempt_hash(target_url, retries)
      if retries == 0
        raise "Too many hashing attempts retries"
      end

      # We use uuidv4 here to ensure a 'truly' random (122 bits of randomness, or 2 ** 122) salt to prevent hash collisions.
      # Another possibility is to use a number, the chosen number will be the upper bound of the number of possible
      # salts for a given URL. If a target_url is very popular, the probability of a collision increases every time
      # it is hashed.
      uuid = SecureRandom.uuid_v4
      prefixed_target_url = "#{uuid}#{target_url}"
      hashed_target_url = Digest::SHA256.hexdigest(prefixed_target_url)
      # Slice the first 11 characters and convert it to a decimal number
      hash_as_decimal = hashed_target_url[0..10].to_i(16)
      # Mathematically, the most number of characters from this encoding would be 8. The biggest possible number from
      # the hash is 16 ** 11, or 2 ** 44. For 8 base62 encoded characters, there are 62 ** 8 possible combinations.
      # Since 62 ** 8 > 2 ** 44, we will never have more than 8 characters.
      base62_hashed_target_url = YAB62.encode62(hash_as_decimal)

      # check if this string already exists in the database
      if Url.find_by_hashed_url(base62_hashed_target_url)
        # if it does, repeat the process until there is no collision, or until the max retries is reached
        return attempt_hash(target_url, retries - 1)
      end

      # return the hashed url and the salt used to hash it
      [ base62_hashed_target_url, uuid ]
    end

    # Since we are using a uuid to salt the target_url, the probability of a collision is extremely low.
    max_retries = 20
    self.attempt_hash(target_url, max_retries)
  end
end
