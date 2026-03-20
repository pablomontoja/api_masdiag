require "rails_helper"

RSpec.describe "Toxo::SamplesController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }

  def create_registered_sample(code: "TX001A", patient: toxo_patient)
    sample = create(:toxo_sample, Code: code, patient: patient)
    sample.measurements.create!(ProjectId: 39, Status: 1, MaterialType: 0)
    sample
  end

  # ───── authentication ────────────────────────────────────────────────────────

  describe "authentication" do
    it "returns 401 when no token" do
      get "/toxo/samples"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ───── GET /toxo/samples ─────────────────────────────────────────────────────

  describe "GET /toxo/samples" do
    it "returns only samples belonging to the contractor" do
      sample = create_registered_sample

      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      other_sample     = create_registered_sample(code: "TX002A", patient: other_patient)

      get "/toxo/samples", headers: bearer

      expect(response).to have_http_status(:ok)
      ids = json.map { |s| s["Id"] }
      expect(ids).to include(sample.Id)
      expect(ids).not_to include(other_sample.Id)
    end
  end

  # ───── GET /toxo/samples/:id ─────────────────────────────────────────────────

  describe "GET /toxo/samples/:id" do
    it "returns the sample" do
      sample = create_registered_sample

      get "/toxo/samples/#{sample.Id}", headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["Id"]).to eq(sample.Id)
      expect(json["measurements"]).to be_an(Array)
    end

    it "returns 404 for non-existent sample" do
      get "/toxo/samples/999999", headers: bearer
      expect(response).to have_http_status(:not_found)
    end
  end

  # ───── DELETE /toxo/samples/:id ──────────────────────────────────────────────

  describe "DELETE /toxo/samples/:id" do
    it "destroys sample and measurements when deletable" do
      sample = create_registered_sample

      expect {
        delete "/toxo/samples/#{sample.Id}", headers: bearer
      }.to change(Toxo::Sample, :count).by(-1)
        .and change(Measurement, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 403 when sample is already accepted in lab" do
      sample = create_registered_sample
      sample.update!(AcceptanceDate: Time.current)

      delete "/toxo/samples/#{sample.Id}", headers: bearer

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 when sample belongs to another contractor" do
      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      other_sample     = create_registered_sample(code: "TX002A", patient: other_patient)

      delete "/toxo/samples/#{other_sample.Id}", headers: bearer

      expect(response).to have_http_status(:forbidden)
    end
  end
end
