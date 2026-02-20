class EncountersController < ApplicationController
  include ApiAuthenticatable

  # POST /encounters
  def create
    payload = parse_json_request
    return unless payload

    encounter = Encounter.new(
      encounter_id: payload['encounterId'],
      patient_id: payload['patientId'],
      provider_id: payload['providerId'],
      encounter_date: parse_datetime(payload['encounterDate']),
      encounter_type: payload['encounterType'],
      clinical_data: payload['clinicalData'] || {},
      metadata: payload['metadata'] || {}
    )

    if encounter.save
      render json: { id: encounter.id }, status: :created
    else
      render json: { errors: encounter.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

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

  def parse_datetime(value)
    return nil if value.blank?
    Time.iso8601(value) rescue nil
  end

  def render_bad_request(message)
    render json: { error: message }, status: :bad_request
  end
end
