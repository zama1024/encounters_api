class ApiKey < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end
end