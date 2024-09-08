class Url < ApplicationRecord
  validates :target_url, presence: true
  # note: uniqueness check should not be done here, but on a bloom filter. This is just to
  # maintain the integrity of the table and ensure that the hash is unique.
  validates :hashed_url, presence: true, uniqueness: true
  validates :salt, presence: true, uniqueness: true
  validates :title, presence: true
end
