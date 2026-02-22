require 'rails_helper'

RSpec.describe "Audit::Encounters API", type: :request do
  let!(:user) { User.create!(name: "AuditUser") }
  let!(:api_token_and_record) { user.create_api_key!(name: "audit-key") }
  let(:api_token) { api_token_and_record[:token] }
  let(:headers) { { "Authorization" => "ApiKey #{api_token}", "Accept" => "application/json" } }

  before do
    @enc = Encounter.create!(
      encounter_id: "enc-audit-1",
      patient_id: "audit-patient",
      provider_id: "prov-audit",
      encounter_date: Time.now.utc,
      encounter_type: "initial_assessment",
      clinical_data: {},
      metadata: { "created_at" => Time.now.utc.iso8601, "updated_at" => Time.now.utc.iso8601, "created_by" => "spec" }
    )
  end

  it "records an audit access when an encounter is shown and returns audit entries" do
    # trigger show (this will create an AuditAccess record)
    get "/encounters/#{@enc.id}", headers: headers
    expect(response).to have_http_status(:ok)

    # query audit endpoint for recent accesses
    start_date = (Time.now.utc - 5.minutes).iso8601
    end_date = (Time.now.utc + 5.minutes).iso8601

    get "/audit/encounters", params: { start_date: start_date, end_date: end_date, encounterId: @enc.encounter_id }, headers: headers
    expect(response).to have_http_status(:ok)

    json = JSON.parse(response.body)
    expect(json["data"]).to be_an(Array)
    expect(json["data"].first).to include("encounter_db_id", "accessed_by_user_id", "accessed_at")
    expect(json["meta"]).to include("page", "per_page", "total", "total_pages")
  end

  it "validates pagination params and returns 400 for invalid per_page" do
    get "/audit/encounters", params: { per_page: "0" }, headers: headers
    expect(response).to have_http_status(:bad_request)
    json = JSON.parse(response.body)
    expect(json["error"]).to match(/per_page/i)
  end
end
