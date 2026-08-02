require "rails_helper"

RSpec.describe "Toxo::Samples::ExportsController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }

  def create_sample(code:, dispatch_date:, patient: toxo_patient)
    sample = create(:toxo_sample, Code: code, patient: patient)
    sample.update_column(:dispatch_date, dispatch_date)
    sample
  end

  describe "authentication" do
    it "returns 401 when no token" do
      get "/toxo/samples/exports", params: { dispatch_date_from: "2026-07-01", dispatch_date_to: "2026-07-31" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /toxo/samples/exports" do
    it "returns samples whose dispatch date falls within the inclusive range" do
      in_range   = create_sample(code: "TX001A", dispatch_date: Date.new(2026, 7, 10))
      lower_edge = create_sample(code: "TX002A", dispatch_date: Date.new(2026, 7, 1))
      upper_edge = create_sample(code: "TX003A", dispatch_date: Date.new(2026, 7, 31))
      out_before = create_sample(code: "TX004A", dispatch_date: Date.new(2026, 6, 30))
      out_after  = create_sample(code: "TX005A", dispatch_date: Date.new(2026, 8, 1))

      get "/toxo/samples/exports",
        params: { dispatch_date_from: "2026-07-01", dispatch_date_to: "2026-07-31" },
        headers: bearer

      expect(response).to have_http_status(:ok)
      codes = json["data"].map { |r| r["Code"] }
      expect(codes).to contain_exactly("TX001A", "TX002A", "TX003A")
    end

    it "returns Code, Lot, RegistrationDate, and dispatch_date per row" do
      sample = create_sample(code: "TX001A", dispatch_date: Date.new(2026, 7, 10))
      sample.update_column(:Lot, "LOT001")

      get "/toxo/samples/exports",
        params: { dispatch_date_from: "2026-07-01", dispatch_date_to: "2026-07-31" },
        headers: bearer

      row = json["data"].first
      expect(row.keys).to contain_exactly("Code", "Lot", "RegistrationDate", "dispatch_date")
      expect(row["Code"]).to eq("TX001A")
      expect(row["Lot"]).to eq("LOT001")
    end

    it "orders rows by dispatch_date then Code" do
      create_sample(code: "TX002A", dispatch_date: Date.new(2026, 7, 5))
      create_sample(code: "TX001A", dispatch_date: Date.new(2026, 7, 5))
      create_sample(code: "TX003A", dispatch_date: Date.new(2026, 7, 1))

      get "/toxo/samples/exports",
        params: { dispatch_date_from: "2026-07-01", dispatch_date_to: "2026-07-31" },
        headers: bearer

      codes = json["data"].map { |r| r["Code"] }
      expect(codes).to eq(%w[TX003A TX001A TX002A])
    end

    it "returns an empty list for a range with no matching orders" do
      create_sample(code: "TX001A", dispatch_date: Date.new(2026, 1, 1))

      get "/toxo/samples/exports",
        params: { dispatch_date_from: "2026-07-01", dispatch_date_to: "2026-07-31" },
        headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to eq([])
    end

    it "returns 422 for a reversed date range" do
      get "/toxo/samples/exports",
        params: { dispatch_date_from: "2026-07-31", dispatch_date_to: "2026-07-01" },
        headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when required params are missing" do
      get "/toxo/samples/exports", params: { dispatch_date_from: "2026-07-01" }, headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "only returns orders within the policy scope" do
      create_sample(code: "TX001A", dispatch_date: Date.new(2026, 7, 10))

      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      create_sample(code: "TX002A", dispatch_date: Date.new(2026, 7, 10), patient: other_patient)

      get "/toxo/samples/exports",
        params: { dispatch_date_from: "2026-07-01", dispatch_date_to: "2026-07-31" },
        headers: bearer

      codes = json["data"].map { |r| r["Code"] }
      expect(codes).to eq([ "TX001A" ])
    end
  end
end
