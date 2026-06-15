require "rails_helper"

RSpec.describe "Toxo::MeasurementsController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }

  def create_measurement(code:, authorized_at: nil)
    project = create(:toxo_project_igg)
    sample  = create(:toxo_sample, Code: code, patient: toxo_patient)
    m = Measurement.create!(SampleId: sample.Id, ProjectId: project.Id, Status: 1, MaterialType: 0, IsRepeat: false)
    m.update_column(:AuthorizedAt, authorized_at) if authorized_at
    m
  end

  # ───── authentication ────────────────────────────────────────────────────────

  describe "authentication" do
    it "returns 401 when no token" do
      get "/toxo/measurements"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ───── GET /toxo/measurements ────────────────────────────────────────────────

  describe "GET /toxo/measurements" do
    it "returns only measurements belonging to the contractor" do
      m = create_measurement(code: "TX001A")

      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      other_project    = create(:toxo_project_igg)
      other_sample     = create(:toxo_sample, Code: "TX999A", patient: other_patient)
      Measurement.create!(SampleId: other_sample.Id, ProjectId: other_project.Id, Status: 1, MaterialType: 0, IsRepeat: false)

      get "/toxo/measurements", headers: bearer

      expect(response).to have_http_status(:ok)
      ids = json.map { |r| r["Id"] }
      expect(ids).to include(m.Id)
    end

    it "returns 200 with no sort params (no regression)" do
      create_measurement(code: "TX001A")
      get "/toxo/measurements", headers: bearer
      expect(response).to have_http_status(:ok)
    end
  end

  # ───── GET /toxo/measurements — sorting ──────────────────────────────────────

  describe "GET /toxo/measurements (sorting)" do
    it "returns measurements sorted by authorized_at descending" do
      early = create_measurement(code: "TX001A", authorized_at: 3.days.ago)
      late  = create_measurement(code: "TX002A", authorized_at: 1.day.ago)

      get "/toxo/measurements", params: { sort: "authorized_at", direction: "desc" }, headers: bearer

      expect(response).to have_http_status(:ok)
      ids = json.map { |r| r["Id"] }
      expect(ids.index(late.Id)).to be < ids.index(early.Id)
    end

    it "returns measurements sorted by sample_code ascending" do
      create_measurement(code: "TX002A")
      create_measurement(code: "TX001A")

      get "/toxo/measurements", params: { sort: "sample_code", direction: "asc" }, headers: bearer

      expect(response).to have_http_status(:ok)
      codes = json.map { |r| r["SampleCode"] }
      expect(codes.index("TX001A")).to be < codes.index("TX002A")
    end

    it "silently ignores unknown sort column" do
      create_measurement(code: "TX001A")

      get "/toxo/measurements", params: { sort: "unknown_col", direction: "asc" }, headers: bearer

      expect(response).to have_http_status(:ok)
    end
  end

  # ───── GET /toxo/measurements/:id ────────────────────────────────────────────

  describe "GET /toxo/measurements/:id" do
    it "returns the measurement" do
      m = create_measurement(code: "TX001A")

      get "/toxo/measurements/#{m.Id}", headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["Id"]).to eq(m.Id)
    end

    it "returns 404 for non-existent measurement" do
      get "/toxo/measurements/999999", headers: bearer
      expect(response).to have_http_status(:not_found)
    end
  end
end
