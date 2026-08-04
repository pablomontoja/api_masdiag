require "rails_helper"

RSpec.describe "Toxo::Measurements::ExportsController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }

  def create_measurement(code:, authorized_at: nil, patient: toxo_patient)
    project = create(:toxo_project_igg)
    sample  = create(:toxo_sample, Code: code, patient: patient)
    m = Measurement.create!(SampleId: sample.Id, ProjectId: project.Id, Status: 1, MaterialType: 0, IsRepeat: false)
    m.update_column(:AuthorizedAt, authorized_at) if authorized_at
    m
  end

  describe "authentication" do
    it "returns 401 when no token" do
      get "/toxo/measurements/exports",
        params: { authorized_at_from: "2026-07-01", authorized_at_to: "2026-07-31" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /toxo/measurements/exports" do
    it "returns measurements whose AuthorizedAt falls within the inclusive range" do
      in_range   = create_measurement(code: "TX001A", authorized_at: Time.zone.local(2026, 7, 10, 12))
      lower_edge = create_measurement(code: "TX002A", authorized_at: Time.zone.local(2026, 7, 1, 0))
      upper_edge = create_measurement(code: "TX003A", authorized_at: Time.zone.local(2026, 7, 31, 23, 59))
      out_before = create_measurement(code: "TX004A", authorized_at: Time.zone.local(2026, 6, 30, 23))
      out_after  = create_measurement(code: "TX005A", authorized_at: Time.zone.local(2026, 8, 1, 1))
      not_authorized = create_measurement(code: "TX006A")

      get "/toxo/measurements/exports",
        params: { authorized_at_from: "2026-07-01", authorized_at_to: "2026-07-31" },
        headers: bearer

      expect(response).to have_http_status(:ok)
      ids = json["data"].map { |r| r["Id"] }
      expect(ids).to contain_exactly(in_range.Id, lower_edge.Id, upper_edge.Id)
    end

    it "includes SampleCode, ProjectId, AuthorizedAt, and report_pdf_url per row" do
      m = create_measurement(code: "TX001A", authorized_at: Time.zone.local(2026, 7, 10))

      get "/toxo/measurements/exports",
        params: { authorized_at_from: "2026-07-01", authorized_at_to: "2026-07-31" },
        headers: bearer

      row = json["data"].first
      expect(row["SampleCode"]).to eq("TX001A")
      expect(row["ProjectId"]).to eq(m.ProjectId)
      expect(row).to have_key("report_pdf_url")
    end

    it "returns an empty list for a range with no authorized measurements" do
      create_measurement(code: "TX001A", authorized_at: Time.zone.local(2026, 1, 1))

      get "/toxo/measurements/exports",
        params: { authorized_at_from: "2026-07-01", authorized_at_to: "2026-07-31" },
        headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to eq([])
    end

    it "returns 422 for a reversed date range" do
      get "/toxo/measurements/exports",
        params: { authorized_at_from: "2026-07-31", authorized_at_to: "2026-07-01" },
        headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when required params are missing" do
      get "/toxo/measurements/exports", params: { authorized_at_from: "2026-07-01" }, headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "only returns measurements within the policy scope" do
      in_scope = create_measurement(code: "TX001A", authorized_at: Time.zone.local(2026, 7, 10))

      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      create_measurement(code: "TX002A", authorized_at: Time.zone.local(2026, 7, 10), patient: other_patient)

      get "/toxo/measurements/exports",
        params: { authorized_at_from: "2026-07-01", authorized_at_to: "2026-07-31" },
        headers: bearer

      ids = json["data"].map { |r| r["Id"] }
      expect(ids).to eq([ in_scope.Id ])
    end
  end
end
