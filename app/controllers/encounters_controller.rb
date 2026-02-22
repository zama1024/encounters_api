class EncountersController < ApplicationController
  include ApiAuthenticatable

  before_action :create_audit_record, only: [:show]

  # POST /encounters
  def create
    payload = parse_json_request
    return unless payload

    result = EncounterCreator.new(payload: payload).call
    if result.success?
      render json: { id: result.encounter.id }, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
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

    render json: EncounterSerializer.serialize(encounter), status: :ok
  end

  private

  def encounter
    @encounter ||= Encounter.find_by(id: params[:id]) || Encounter.find_by(encounter_id: params[:id])
  end

  def create_audit_record
    AuditRecorder.record_view(encounter: encounter, current_user: @current_api_user)
  end
end
