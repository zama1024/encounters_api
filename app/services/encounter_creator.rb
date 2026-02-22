class EncounterCreator
  Result = Struct.new(:success?, :encounter, :errors)

  def initialize(payload:)
    @payload = payload || {}
  end

  def call
    encounter = Encounter.new(
      encounter_id: @payload['encounterId'],
      patient_id: @payload['patientId'],
      provider_id: @payload['providerId'],
      encounter_date: parse_datetime(@payload['encounterDate']),
      encounter_type: @payload['encounterType'],
      clinical_data: @payload['clinicalData'] || {},
      metadata: @payload['metadata'] || {}
    )

    if encounter.save
      Result.new(true, encounter, nil)
    else
      Result.new(false, nil, encounter.errors.full_messages)
    end
  end

  private

  def parse_datetime(value)
    return nil if value.blank?
    Time.iso8601(value) rescue nil
  end
end
