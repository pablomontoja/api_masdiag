require "rails_helper"

RSpec.describe "Toxo registration → order confirmation notification", type: :request do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:session)     { create(:session, contractor: contractor) }
  let(:bearer)       { { "Authorization" => "Bearer #{session.token}" } }

  let!(:toxo_patient)     { create(:toxo_patient, contractor: contractor) }
  let!(:toxo_project_igg) { create(:toxo_project_igg) }
  let!(:rsc) { ReservedSampleCode.create!(Code: "TX001A", InstitutionId: institution.id, IsRetailSale: true, CreatedAt: Time.now, expiry_date: 1.year.since) }

  let(:valid_params) do
    {
      Code: "TX001A", MaterialType: 0, dispatch_date: Date.today.to_s,
      sample_collection_date: Date.today.to_s, post_examination_procedure: 0,
      infectious_risk: 0, execution_mode: 0, project_ids: [39]
    }
  end

  it "enqueues SampleRegistrationConfirmationJob on a successful registration" do
    expect(Notifications::SampleRegistrationConfirmationJob).to receive(:perform_later)
    post "/toxo/samples/registrations", params: valid_params, headers: bearer
    expect(response).to have_http_status(:created)
  end

  it "does NOT enqueue SampleRegistrationConfirmationJob when registration fails validation" do
    expect(Notifications::SampleRegistrationConfirmationJob).not_to receive(:perform_later)
    post "/toxo/samples/registrations", params: valid_params.merge(project_ids: []), headers: bearer
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "returns 401 and does not enqueue when the Bearer token is missing/invalid" do
    expect(Notifications::SampleRegistrationConfirmationJob).not_to receive(:perform_later)
    post "/toxo/samples/registrations", params: valid_params,
                                        headers: { "Authorization" => "Bearer invalid" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 403 and does not enqueue when the contractor cannot add samples (Pundit denies)" do
    contractor.update!(can_add_samples: false)
    expect(Notifications::SampleRegistrationConfirmationJob).not_to receive(:perform_later)
    post "/toxo/samples/registrations", params: valid_params, headers: bearer
    expect(response).to have_http_status(:forbidden)
  end
end
