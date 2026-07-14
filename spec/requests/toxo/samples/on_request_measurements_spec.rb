require "rails_helper"

RSpec.describe "Toxo::Samples::OnRequestMeasurementsController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }
  let!(:toxo_project_igm) { create(:toxo_project_igm) }
  let!(:toxo_project_on_request) { create(:toxo_project_on_request) }

  def create_sample(comment: nil)
    create(:toxo_sample, patient: toxo_patient, Comment: comment)
  end

  def create_qualitative_measurement(sample)
    Measurement.create!(SampleId: sample.Id, ProjectId: toxo_project_igm.Id, Status: 5, MaterialType: 0, IsRepeat: false)
  end

  # ───── authentication ────────────────────────────────────────────────────────

  describe "authentication" do
    it "returns 401 when no token" do
      post "/toxo/samples/on_request_measurements"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ───── POST /toxo/samples/on_request_measurements ───────────────────────────

  describe "POST /toxo/samples/on_request_measurements" do
    it "creates an on-request measurement and returns 201" do
      sample = create_sample
      create_qualitative_measurement(sample)

      post "/toxo/samples/on_request_measurements", params: { sample_id: sample.Id, note: "Proszę o dodatkowe badanie" }, headers: bearer

      expect(response).to have_http_status(:created)
      measurement = sample.measurements.find_by(ProjectId: 42)
      expect(measurement).to be_present
      expect(measurement.Status).to eq(1)
      expect(measurement.IsRepeat).to eq(false)
    end

    it "appends the note to a blank comment" do
      sample = create_sample(comment: nil)
      create_qualitative_measurement(sample)

      post "/toxo/samples/on_request_measurements", params: { sample_id: sample.Id, note: "Nowa notatka" }, headers: bearer

      expect(response).to have_http_status(:created)
      expect(sample.reload.Comment).to include("Nowa notatka")
    end

    it "preserves prior comment content and appends the new note" do
      sample = create_sample(comment: "Stara notatka o próbce")
      create_qualitative_measurement(sample)

      post "/toxo/samples/on_request_measurements", params: { sample_id: sample.Id, note: "Nowa notatka" }, headers: bearer

      expect(response).to have_http_status(:created)
      reloaded = sample.reload.Comment
      expect(reloaded).to include("Stara notatka o próbce")
      expect(reloaded).to include("Nowa notatka")
    end

    it "returns 422 when an on-request measurement already exists for the sample" do
      sample = create_sample
      create_qualitative_measurement(sample)
      Measurement.create!(SampleId: sample.Id, ProjectId: 42, Status: 7, MaterialType: 0, IsRepeat: false)

      post "/toxo/samples/on_request_measurements", params: { sample_id: sample.Id, note: "Kolejna próba" }, headers: bearer

      expect(response).to have_http_status(:unprocessable_entity)
      expect(sample.measurements.where(ProjectId: 42).count).to eq(1)
    end

    it "returns 422 when note is blank" do
      sample = create_sample
      create_qualitative_measurement(sample)

      post "/toxo/samples/on_request_measurements", params: { sample_id: sample.Id, note: "" }, headers: bearer

      expect(response).to have_http_status(:unprocessable_entity)
      expect(sample.measurements.where(ProjectId: 42)).to be_empty
    end

    it "returns 403 when contractor cannot add samples" do
      contractor.update!(can_add_samples: false)
      sample = create_sample
      create_qualitative_measurement(sample)

      post "/toxo/samples/on_request_measurements", params: { sample_id: sample.Id, note: "Notatka" }, headers: bearer

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 when the sample belongs to another contractor" do
      other_contractor = create(:contractor, institution_id: institution.id, can_add_samples: true)
      other_patient     = create(:toxo_patient, contractor: other_contractor)
      other_sample      = create(:toxo_sample, patient: other_patient)
      create_qualitative_measurement(other_sample)

      post "/toxo/samples/on_request_measurements", params: { sample_id: other_sample.Id, note: "Notatka" }, headers: bearer

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for an unknown sample_id" do
      post "/toxo/samples/on_request_measurements", params: { sample_id: 999_999, note: "Notatka" }, headers: bearer
      expect(response).to have_http_status(:not_found)
    end
  end
end
