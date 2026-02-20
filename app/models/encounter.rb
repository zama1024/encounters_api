class Encounter < ApplicationRecord
  ENCOUNTER_TYPES = %w[initial_assessment follow_up treatment_session].freeze

  validates :encounter_id, presence: { message: "encounterId is required" }, uniqueness: { message: "encounterId must be unique" }
  validates :patient_id, presence: { message: "patientId is required" }
  validates :provider_id, presence: { message: "providerId is required" }
  validates :encounter_date, presence: { message: "encounterDate is required" }
  validates :encounter_type, presence: { message: "encounterType is required" }, inclusion: { in: ENCOUNTER_TYPES, message: "encounterType must be one of: #{ENCOUNTER_TYPES.join(', ')}" }

  validate  :encounter_date_must_be_valid
  validate  :clinical_data_is_json_object
  validate  :metadata_has_required_audit_fields

  private

  def encounter_date_must_be_valid
    return if encounter_date.blank?

    if encounter_date.is_a?(String)
      begin
        Time.iso8601(encounter_date)
      rescue ArgumentError
        errors.add(:encounter_date, "encounterDate must be a valid ISO8601 timestamp")
      end
    else
      valid = encounter_date.respond_to?(:to_time) || encounter_date.is_a?(Date) || encounter_date.is_a?(Time)
      errors.add(:encounter_date, "encounterDate must be a valid timestamp") unless valid
    end
  end

  def clinical_data_is_json_object
    unless clinical_data.is_a?(Hash)
      errors.add(:clinical_data, "clinicalData must be a JSON object")
    end
  end

  def metadata_has_required_audit_fields
    unless metadata.is_a?(Hash)
      errors.add(:metadata, "metadata must be a JSON object")
      return
    end

    required = %w[created_at updated_at created_by]
    missing = required.select { |k| metadata[k].blank? }
    if missing.any?
      errors.add(:metadata, "missing audit fields: #{missing.join(', ')}")
    end
  end
end
