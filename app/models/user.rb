class User < ApplicationRecord
  has_many :api_keys, dependent: :destroy

  validates :name, presence: true

  # Creates a new API key record and returns the plaintext token (shown once)
  def create_api_key!(name: nil)
    token = SecureRandom.urlsafe_base64(48) # high-entropy token
    digest = BCrypt::Password.create(token)
    api_key = api_keys.create!(token_digest: digest, key_name: name)
    { token: token, api_key: api_key }
  end

  # Returns the ApiKey record if token is valid and not revoked, otherwise nil
  def authenticate_api_key(token)
    api_keys.where(revoked_at: nil).detect do |k|
      BCrypt::Password.new(k.token_digest) == token
    rescue BCrypt::Errors::InvalidHash
      false
    end
  end
end