class Url < ApplicationRecord
  validates :target_url, presence: true
  # note: uniqueness check should not be done here, but on a bloom filter. This is just to
  # maintain the integrity of the table and ensure that the hash is unique.
  validates :hashed_url, presence: true, uniqueness: true
  validates :salt, presence: true, uniqueness: true
  validates :title, presence: true
  attribute :short_url, :string
  after_initialize :generate_short_url

  validate :validate_target_url

  private

  def validate_target_url
    begin
      UrlHasher.validate(self.target_url)
    rescue
      errors.add(:base, "Invalid target_url provided")
    end
  end

  def generate_short_url
    if Rails.env.production?
      url = "https://api.url.weiyuan.dev"
    else
      url = "http://localhost:3000"
    end

    self.short_url = "#{url}/#{self.hashed_url}"
  end
end
