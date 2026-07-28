require "rails_helper"

RSpec.describe "Toxo::Measurements::ChromatogramRequestsController", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false, email: "kontrahent@example.com") }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }
  let!(:toxo_project_igg) { create(:toxo_project_igg) }
  let!(:toxo_project_igm) { create(:toxo_project_igm) }

  def create_measurement(project_id: 39, status: 5, authorized_at: nil, code: "TX001A")
    sample = create(:toxo_sample, Code: code, patient: toxo_patient)
    Measurement.create!(SampleId: sample.Id, ProjectId: project_id, Status: status, MaterialType: 0, IsRepeat: false).tap do |m|
      m.update_column(:AuthorizedAt, authorized_at) if authorized_at
    end
  end

  around do |example|
    original = Toxo::Constants::CHROMATOGRAM_REQUEST_INSTITUTION_IDS
    Toxo::Constants.send(:remove_const, :CHROMATOGRAM_REQUEST_INSTITUTION_IDS)
    Toxo::Constants.const_set(:CHROMATOGRAM_REQUEST_INSTITUTION_IDS, [ institution.id ].freeze)
    example.run
  ensure
    Toxo::Constants.send(:remove_const, :CHROMATOGRAM_REQUEST_INSTITUTION_IDS)
    Toxo::Constants.const_set(:CHROMATOGRAM_REQUEST_INSTITUTION_IDS, original)
  end

  describe "authentication" do
    it "returns 401 when no token" do
      measurement = create_measurement
      post "/toxo/measurements/#{measurement.Id}/chromatogram_requests"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /toxo/measurements/:measurement_id/chromatogram_requests" do
    context "when the measurement is authorized and eligible" do
      it "returns 201, sends the notification email, and creates a Note on the measurement" do
        measurement = create_measurement(project_id: 39, status: 5)

        expect {
          post "/toxo/measurements/#{measurement.Id}/chromatogram_requests", headers: bearer
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:created)
        expect(json["status"]).to eq("requested")

        note = measurement.notes.find_by(key: "chromatogram-request-email")
        expect(note).to be_present
        expect(note.description).to include("kontrahent@example.com")
        expect(note.description).to include(measurement.sample.Code)
        expect(note.description).to include(Toxo::Constants::PROJECT_NAMES[39])

        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to include("toxo@masdiag.pl")
        expect(mail.body.encoded).to include("kontrahent@example.com")
        expect(mail.body.encoded).to include(measurement.sample.Code)
      end

      it "treats AuthorizedAt presence as authorized even when Status is not 5" do
        measurement = create_measurement(project_id: 39, status: 4, authorized_at: 1.day.ago)

        post "/toxo/measurements/#{measurement.Id}/chromatogram_requests", headers: bearer

        expect(response).to have_http_status(:created)
      end

      it "makes the measurement report has_chromatogram_request: true afterwards" do
        measurement = create_measurement(project_id: 39, status: 5)

        post "/toxo/measurements/#{measurement.Id}/chromatogram_requests", headers: bearer
        get "/toxo/measurements/#{measurement.Id}", headers: bearer

        expect(json["has_chromatogram_request"]).to eq(true)
      end
    end

    context "idempotency (a second request for the same measurement)" do
      it "returns 200 already_requested and does not send a duplicate email or note" do
        measurement = create_measurement(project_id: 39, status: 5)
        post "/toxo/measurements/#{measurement.Id}/chromatogram_requests", headers: bearer
        expect(response).to have_http_status(:created)

        expect {
          post "/toxo/measurements/#{measurement.Id}/chromatogram_requests", headers: bearer
        }.to_not change { ActionMailer::Base.deliveries.count }

        expect(response).to have_http_status(:ok)
        expect(json["status"]).to eq("already_requested")
        expect(measurement.notes.where(key: "chromatogram-request-email").count).to eq(1)
      end
    end

    context "when the contractor's institution is not eligible" do
      it "returns 403" do
        other_institution = create(:institution)
        other_contractor = create(:contractor, institution_id: other_institution.id, can_add_samples: true)
        other_session = create(:session, contractor: other_contractor)
        other_patient = create(:toxo_patient, contractor: other_contractor)
        other_sample = create(:toxo_sample, Code: "TX777A", patient: other_patient)
        measurement = Measurement.create!(SampleId: other_sample.Id, ProjectId: 39, Status: 5, MaterialType: 0, IsRepeat: false)

        post "/toxo/measurements/#{measurement.Id}/chromatogram_requests",
             headers: { "Authorization" => "Bearer #{other_session.token}" }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the measurement is not authorized" do
      it "returns 422" do
        measurement = create_measurement(project_id: 39, status: 1)

        post "/toxo/measurements/#{measurement.Id}/chromatogram_requests", headers: bearer

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when the measurement's ProjectId is not eligible" do
      it "returns 422" do
        measurement = create_measurement(project_id: 40, status: 5)

        post "/toxo/measurements/#{measurement.Id}/chromatogram_requests", headers: bearer

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
