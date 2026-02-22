require 'rails_helper'

RSpec.describe "Encounters API", type: :request do
  let!(:user) { User.create!(name: "SpecUser") }
  let!(:api_token_and_record) { user.create_api_key!(name: "spec-key") }
  let(:api_token) { api_token_and_record[:token] }
  let(:headers) { { "Authorization" => "ApiKey #{api_token}", "Content-Type" => "application/json", "Accept" => "application/json" } }

  describe "POST /encounters" do
    let(:base_payload) {
      {
        "encounterId" => "enc-001",
        "patientId" => "patient-12345",
        "providerId" => "prov-99",
        "encounterDate" => Time.now.utc.iso8601,
        "encounterType" => "initial_assessment",
        "clinicalData" => { "notes" => "test" },
        "metadata" => { "created_at" => Time.now.utc.iso8601, "updated_at" => Time.now.utc.iso8601, "created_by" => "spec" }
      }
    }

    it "creates an encounter and returns id" do
      post "/encounters", params: base_payload.to_json, headers: headers
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["id"]).to be_present
      created = Encounter.find(json["id"])
      expect(created.encounter_id).to eq("enc-001")
      expect(created.patient_id).to eq("patient-12345")
    end

    it "returns validation errors for missing required fields" do
      payload = base_payload.except("encounterId")
      post "/encounters", params: payload.to_json, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_an(Array)
      expect(json["errors"].join).to match(/encounterId/i)
    end
  end

  describe "GET /encounters/:id (show with filters)" do
    let!(:encounter) {
      Encounter.create!(
        encounter_id: "enc-lookup-1",
        patient_id: "patient-xyz",
        provider_id: "prov-55",
        encounter_date: Time.now.utc,
        encounter_type: "initial_assessment",
        clinical_data: {},
        metadata: { "created_at" => Time.now.utc.iso8601, "updated_at" => Time.now.utc.iso8601, "created_by" => "spec" }
      )
    }

    it "returns the encounter when filters match" do
      get "/encounters/#{encounter.id}", params: { patientId: "patient-xyz" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["encounterId"]).to eq("enc-lookup-1")
      expect(json["patientId"]).to eq("patient-xyz")
    end

    it "returns 404 when a provided filter does not match" do
      get "/encounters/#{encounter.id}", params: { patientId: "wrong-patient" }, headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "can find by encounterId and apply filters" do
      get "/encounters/#{encounter.encounter_id}", params: { providerId: "prov-55" }, headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["encounterId"]).to eq("enc-lookup-1")
    end

    it "returns 404 when no encounter found by id or encounterId" do
      get "/encounters/999999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
