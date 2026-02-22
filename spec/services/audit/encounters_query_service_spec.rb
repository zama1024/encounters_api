require 'rails_helper'

RSpec.describe Audit::EncountersQueryService, type: :service do
  let!(:user) { User.create!(name: "AuditSpecUser") }
  let!(:encounter) {
    Encounter.create!(
      encounter_id: "enc-query-1",
      patient_id: "patient-query",
      provider_id: "prov-query",
      encounter_date: Time.now.utc,
      encounter_type: "initial_assessment",
      clinical_data: {},
      metadata: { "created_at" => Time.now.utc.iso8601, "updated_at" => Time.now.utc.iso8601, "created_by" => "spec" }
    )
  }

  before do
    AuditAccess.create!(
      encounter: encounter,
      accessed_by_user_id: user.id,
      accessed_at: Time.now.utc
    )
  end

  describe '#call' do
    it "returns paginated results with default pagination" do
      result = Audit::EncountersQueryService.new(params: {}).call
      expect(result.success).to be true
      expect(result.records).to be_an(Array)
      expect(result.meta).to include(:page, :perPage, :total, :totalPages)
      expect(result.meta[:page]).to eq(1)
      expect(result.meta[:perPage]).to eq(50)
    end

    it "filters by userId" do
      result = Audit::EncountersQueryService.new(params: { userId: user.id }).call
      expect(result.success).to be true
      expect(result.records.first[:accessed_by_user_id]).to eq(user.id)
    end

    it "filters by encounterId" do
      result = Audit::EncountersQueryService.new(params: { encounterId: encounter.encounter_id }).call
      expect(result.success).to be true
      expect(result.records.first[:encounter_db_id]).to eq(encounter.id)
    end

    it "returns empty results for non-existent encounterId" do
      result = Audit::EncountersQueryService.new(params: { encounterId: "non-existent" }).call
      expect(result.success).to be true
      expect(result.records).to be_empty
    end

    it "parses ISO8601 timestamps for startDate and endDate" do
      start = (Time.now.utc - 5.minutes).iso8601
      finish = (Time.now.utc + 5.minutes).iso8601
      result = Audit::EncountersQueryService.new(params: { startDate: start, endDate: finish }).call
      expect(result.success).to be true
      expect(result.errors).to be_empty
    end

    it "parses YYYY-MM-DD date format for startDate" do
      today = Date.today.iso8601
      result = Audit::EncountersQueryService.new(params: { startDate: today }).call
      expect(result.success).to be true
      expect(result.errors).to be_empty
    end

    it "rejects invalid startDate and sets error" do
      result = Audit::EncountersQueryService.new(params: { startDate: "invalid-date" }).call
      expect(result.success).to be false
      expect(result.errors).to include(/startDate must be/)
    end

    it "rejects invalid endDate and sets error" do
      result = Audit::EncountersQueryService.new(params: { endDate: "not-a-date" }).call
      expect(result.success).to be false
      expect(result.errors).to include(/endDate must be/)
    end

    it "respects pagination from params" do
      result = Audit::EncountersQueryService.new(params: { page: '1', perPage: '10' }).call
      expect(result.success).to be true
      expect(result.meta[:page]).to eq(1)
      expect(result.meta[:perPage]).to eq(10)
    end

    it "returns error for invalid page param" do
      result = Audit::EncountersQueryService.new(params: { page: 'abc' }).call
      expect(result.success).to be false
      expect(result.errors).to include(/page must be/)
    end

    it "returns error for invalid perPage param" do
      result = Audit::EncountersQueryService.new(params: { perPage: '2000' }).call
      expect(result.success).to be false
      expect(result.errors).to include(/perPage must be/)
    end

    it "includes serialized audit record fields" do
      result = Audit::EncountersQueryService.new(params: {}).call
      expect(result.success).to be true
      expect(result.records.first).to include(:id, :encounter_db_id, :accessed_by_user_id, :accessed_at)
    end
  end
end
