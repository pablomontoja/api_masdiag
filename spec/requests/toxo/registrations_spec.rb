require "rails_helper"

RSpec.describe "Toxo::Samples::RegistrationsController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }
  let!(:toxo_project_igg) { create(:toxo_project_igg) }
  let!(:toxo_project_igm) { create(:toxo_project_igm) }
  let!(:rsc) { ReservedSampleCode.create!(Code: "TX001A", InstitutionId: institution.id, IsRetailSale: true, CreatedAt: Time.now, expiry_date: 1.year.since) }

  # ───── authentication ────────────────────────────────────────────────────────

  describe "authentication" do
    it "returns 401 when no token" do
      post "/toxo/samples/registrations"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for invalid token" do
      post "/toxo/samples/registrations", headers: { "Authorization" => "Bearer invalid" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ───── GET /toxo/samples/registrations/new ───────────────────────────────────

  describe "GET /toxo/samples/registrations/new" do
    it "returns list of toxo projects" do
      get "/toxo/samples/registrations/new", headers: bearer

      expect(response).to have_http_status(:ok)
      project_ids = json["projects"].map { |p| p["id"] }
      expect(project_ids).to match_array(Toxo::Constants::TOXO_PROJECT_IDS)
    end

    it "returns 403 when contractor cannot add samples" do
      contractor.update!(can_add_samples: false)
      get "/toxo/samples/registrations/new", headers: bearer
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ───── POST /toxo/samples/registrations ──────────────────────────────────────

  describe "POST /toxo/samples/registrations" do
    let(:valid_params) do
      {
        Code:                       "TX001A",
        MaterialType:               0,
        Lot:                        "LOT001",
        dispatch_date:              Date.today.to_s,
        sample_collection_date:     Date.today.to_s,
        post_examination_procedure: 0,
        infectious_risk:            0,
        execution_mode:             0,
        project_ids:                [39]
      }
    end

    it "creates sample with measurements and returns 201" do
      post "/toxo/samples/registrations", params: valid_params, headers: bearer

      expect(response).to have_http_status(:created)
      expect(json["Code"]).to eq("TX001A")
      expect(json["measurements"].length).to eq(1)
      expect(json["measurements"].first["ProjectId"]).to eq(39)
    end

    it "adds IgG (39) automatically when IgM (40) is included" do
      post "/toxo/samples/registrations",
           params: valid_params.merge(project_ids: [40]),
           headers: bearer

      expect(response).to have_http_status(:created)
      project_ids = json["measurements"].map { |m| m["ProjectId"] }
      expect(project_ids).to include(39, 40)
    end

    it "returns 422 when Code is missing" do
      post "/toxo/samples/registrations",
           params: valid_params.merge(Code: ""),
           headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("Code")
    end

    it "returns 422 when project_ids is empty" do
      post "/toxo/samples/registrations",
           params: valid_params.merge(project_ids: []),
           headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 when contractor cannot add samples" do
      contractor.update!(can_add_samples: false)
      post "/toxo/samples/registrations", params: valid_params, headers: bearer
      expect(response).to have_http_status(:forbidden)
    end

    it "creates a sample when sample_collection_date is blank" do
      post "/toxo/samples/registrations",
           params: valid_params.merge(sample_collection_date: ""),
           headers: bearer

      expect(response).to have_http_status(:created)
      expect(json["sample_collection_date"]).to be_nil
    end

    it "returns 422 when sample_collection_date is in the future" do
      post "/toxo/samples/registrations",
           params: valid_params.merge(sample_collection_date: 1.day.from_now.to_date.to_s),
           headers: bearer

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("sample_collection_date")
    end

    it "creates a sample when sample_collection_date is a valid past date" do
      post "/toxo/samples/registrations",
           params: valid_params.merge(sample_collection_date: 3.days.ago.to_date.to_s),
           headers: bearer

      expect(response).to have_http_status(:created)
    end

    it "sets SampleStatus to 3 when SampleStatus 3 (hold order) is submitted" do
      post "/toxo/samples/registrations",
           params: valid_params.merge(SampleStatus: 3),
           headers: bearer

      expect(response).to have_http_status(:created)
      expect(json["SampleStatus"]).to eq(3)
    end

    it "ignores any other SampleStatus submitted by the client" do
      post "/toxo/samples/registrations",
           params: valid_params.merge(SampleStatus: 5),
           headers: bearer

      expect(response).to have_http_status(:created)
      expect(json["SampleStatus"]).to eq(1)
    end
  end
end
