module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_with_api_key!
  end

  private

  def authenticate_with_api_key!
    token = extract_api_token_from_request
    unless token
      render_unauthorized("Missing API key") and return
    end

    api_key_record = find_api_key_record(token)
    unless api_key_record
      render_unauthorized("Invalid API key") and return
    end

    @current_api_key = api_key_record
    @current_api_user = api_key_record.user
  end

  def extract_api_token_from_request
    auth = request.headers['Authorization'].to_s
    return $1 if auth =~ /\AApiKey\s+(.+)\z/i
    request.headers['X-API-Key'].presence
  end

  def find_api_key_record(token)
    return nil if token.blank?
    ApiKey.where(revoked_at: nil).detect do |k|
      begin
        BCrypt::Password.new(k.token_digest) == token
      rescue BCrypt::Errors::InvalidHash
        false
      end
    end
  end

  def render_unauthorized(message)
    # Do not echo sensitive inputs back; return generic messages
    render json: { error: message }, status: :unauthorized
  end
end
