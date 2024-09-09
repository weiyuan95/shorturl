class HashedUrlVisit < ApplicationRecord
  validates :hashed_url, presence: true
  validates :ip, presence: true, format: { with: Resolv::AddressRegex }
  validates :country, presence: true
end
