class EncounterSerializer
  def self.serialize(e)
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
end
