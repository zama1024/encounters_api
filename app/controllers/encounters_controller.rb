class EncountersController < ApplicationController
  include ApiAuthenticatable

  before_action :create_audit_access, only: [:show]

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

  # GET /encounters/:id
  def show
    return render_not_found unless encounter

    filter_service = EncounterFilterService.new(params)
    unless filter_service.valid?
      render_bad_request(filter_service.errors.join('; ')) and return
    end

    unless filter_service.matches?(encounter)
      return render_not_found
    end

    render json: serialize_encounter(encounter), status: :ok
  end

  private

  def encounter
    @encounter ||= Encounter.find_by(id: params[:id]) || Encounter.find_by(encounter_id: params[:id])
  end

  def create_audit_access
    AuditAccess.create!(
      encounter: encounter,
      accessed_by_user_id: @current_api_user&.id,
      accessed_at: Time.current
    ) if encounter.present?
  end

  def serialize_encounter(e)
    {
      id: e.id,
      encounterId: e.encounter_id,
      patientId: e.patient_id,
      providerId: e.provider_id,
      encounterDate: (e.encounter_date.iso8601 rescue nil),
      encounterType: e.encounter_type,
      clinicalData: e.clinical_data,
      metadata: e.metadata,
      createdAt: e.created_at&.iso8601,
      updatedAt: e.updated_at&.iso8601
    }
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

  def parse_datetime(value)
    return nil if value.blank?
    Time.iso8601(value) rescue nil
  end

  def render_bad_request(message)
    render json: { error: message }, status: :bad_request
  end

  def render_not_found
    render json: { error: "Encounter not found" }, status: :not_found
  end

  def sanitized_audit_filters(params_hash)
    # Record filter metadata but never persist patientId value
    {
      encounterId: params_hash[:encounterId],
      patientId_present: params_hash[:patientId].present?,
      providerId: params_hash[:providerId],
      encounterType: params_hash[:encounterType],
      encounterDateBefore: params_hash[:encounterDateBefore],
      encounterDateAfter: params_hash[:encounterDateAfter]
    }.compact
  end
end
