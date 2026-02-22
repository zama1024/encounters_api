class ApplicationController < ActionController::API
  def render_bad_request(message)
    render json: { error: message }, status: :bad_request
  end

  def render_not_found
    render json: { error: "Encounter not found" }, status: :not_found
  end

  def parse_json_request
    begin
      body = request.body.read
      return render_bad_request("Empty request body") if body.blank?
      JSON.parse(body)
    rescue JSON::ParserError
      render_bad_request("Invalid JSON payload")
      nil
    end
  end
end
