require "rails_helper"

RSpec.describe "Toxo::DashboardController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }

  def ensure_project(id)
    Project.find_or_create_by(Id: id) do |p|
      p.assign_attributes(Name: "Project #{id}", WithCutter: false, PlateDimensionX: 8,
                           PlateDimensionY: 12, is_blocked_online: false, InjectionVolume: 0,
                           eng_name: "Project #{id}")
    end
  end

  def create_sample(registered_at: Time.current, code: "TX001A")
    sample = create(:toxo_sample, Code: code, patient: toxo_patient)
    sample.update_column(:RegistrationDate, registered_at)
    sample
  end

  def create_authorized_measurement(sample:, project_id: 39, authorized_at: Time.current)
    ensure_project(project_id)
    m = Measurement.create!(SampleId: sample.Id, ProjectId: project_id, Status: 5, MaterialType: 0, IsRepeat: false)
    m.update_column(:AuthorizedAt, authorized_at)
    m
  end

  describe "authentication" do
    it "returns 401 when no token" do
      get "/toxo/dashboard"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /toxo/dashboard" do
    it "defaults to a 30-day window" do
      get "/toxo/dashboard", headers: bearer

      expect(response).to have_http_status(:ok)
      expect(json["window"]).to eq(30)
    end

    it "falls back to 30 for an invalid window value" do
      get "/toxo/dashboard", params: { window: 999 }, headers: bearer

      expect(json["window"]).to eq(30)
    end

    it "accepts 90/180/360 windows" do
      get "/toxo/dashboard", params: { window: 90 }, headers: bearer
      expect(json["window"]).to eq(90)
    end

    it "counts orders registered within the window" do
      create_sample(registered_at: 5.days.ago, code: "TX001A")
      create_sample(registered_at: 45.days.ago, code: "TX002A")

      get "/toxo/dashboard", params: { window: 30 }, headers: bearer

      expect(json["orders_count"]).to eq(1)
    end

    it "counts authorized measurements within the window" do
      sample = create_sample(code: "TX001A")
      create_authorized_measurement(sample: sample, authorized_at: 5.days.ago)
      create_authorized_measurement(sample: sample, project_id: 40, authorized_at: 45.days.ago)

      get "/toxo/dashboard", params: { window: 30 }, headers: bearer

      expect(json["authorized_measurements_count"]).to eq(1)
    end

    it "returns unused reserved codes count independent of window" do
      create(:reserved_sample_code, Code: "AAAAAAA", InstitutionId: institution.id, package: create(:package))
      used_rsc = create(:reserved_sample_code, Code: "BBBBBBB", InstitutionId: institution.id, package: create(:second_package))
      create_sample(code: "TX001A").update_column(:reserved_sample_code_id, used_rsc.Id)

      get "/toxo/dashboard", params: { window: 30 }, headers: bearer
      count_30 = json["unused_reserved_codes_count"]

      get "/toxo/dashboard", params: { window: 360 }, headers: bearer
      count_360 = json["unused_reserved_codes_count"]

      expect(count_30).to eq(1)
      expect(count_30).to eq(count_360)
    end

    it "returns an analysis breakdown by project id" do
      sample = create_sample(code: "TX001A")
      create_authorized_measurement(sample: sample, project_id: 39, authorized_at: 1.day.ago)
      create_authorized_measurement(sample: sample, project_id: 39, authorized_at: 1.day.ago)
      create_authorized_measurement(sample: sample, project_id: 40, authorized_at: 1.day.ago)

      get "/toxo/dashboard", params: { window: 30 }, headers: bearer

      expect(json["analysis_breakdown"]).to eq("39" => 2, "40" => 1)
    end

    it "returns zero counts and a zero-filled series with no data" do
      get "/toxo/dashboard", params: { window: 30 }, headers: bearer

      expect(json["orders_count"]).to eq(0)
      expect(json["authorized_measurements_count"]).to eq(0)
      expect(json["orders_series"]).to all(satisfy { |_date, count| count.zero? })
      expect(json["authorized_series"]).to all(satisfy { |_date, count| count.zero? })
      expect(json["analysis_breakdown"]).to eq({})
    end

    it "only counts data within the requesting contractor's scope" do
      create_sample(code: "TX001A")

      other_contractor = create(:contractor, institution_id: institution.id)
      other_patient    = create(:toxo_patient, contractor: other_contractor)
      other_sample     = create(:toxo_sample, Code: "TX002A", patient: other_patient)
      other_sample.update_column(:RegistrationDate, Time.current)

      get "/toxo/dashboard", params: { window: 30 }, headers: bearer

      expect(json["orders_count"]).to eq(1)
    end
  end
end
