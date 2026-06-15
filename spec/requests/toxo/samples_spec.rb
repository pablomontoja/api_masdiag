require "rails_helper"

RSpec.describe "Toxo::SamplesController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }

  def create_registered_sample(code: "TX001A", patient: toxo_patient)
    project = create(:toxo_project_igg)
    sample = create(:toxo_sample, Code: code, patient: patient)
    Measurement.create!(SampleId: sample.Id, ProjectId: project.Id, Status: 1, MaterialType: 0, IsRepeat: false)
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

  # ───── GET /toxo/samples — sorting ──────────────────────────────────────────

  describe "GET /toxo/samples (sorting)" do
    it "returns samples sorted by dispatch_date ascending" do
      early = create_registered_sample(code: "TX001A")
      early.update_column(:dispatch_date, 3.days.ago)
      late = create_registered_sample(code: "TX002A")
      late.update_column(:dispatch_date, 1.day.ago)

      get "/toxo/samples", params: { sort: "dispatch_date", direction: "asc" }, headers: bearer

      expect(response).to have_http_status(:ok)
      codes = json.map { |s| s["Code"] }
      expect(codes.index("TX001A")).to be < codes.index("TX002A")
    end

    it "returns samples sorted by code descending" do
      create_registered_sample(code: "TX001A")
      create_registered_sample(code: "TX002A")

      get "/toxo/samples", params: { sort: "code", direction: "desc" }, headers: bearer

      expect(response).to have_http_status(:ok)
      codes = json.map { |s| s["Code"] }
      expect(codes.index("TX002A")).to be < codes.index("TX001A")
    end

    it "returns 200 with no sort params (no regression)" do
      create_registered_sample

      get "/toxo/samples", headers: bearer

      expect(response).to have_http_status(:ok)
    end

    it "silently ignores unknown sort column" do
      create_registered_sample

      get "/toxo/samples", params: { sort: "sql_injection", direction: "DROP" }, headers: bearer

      expect(response).to have_http_status(:ok)
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
      sample.update_column(:AcceptanceDate, Time.current)

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
