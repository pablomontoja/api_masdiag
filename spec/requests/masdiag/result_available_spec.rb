require "rails_helper"

RSpec.describe "POST /masdiag/result_available", type: :request do
  let!(:inst) { create(:institution, id: 1) }
  let!(:contractor) { create(:contractor, institution_id: inst.id) }
  let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
  let!(:sample) { create(:sample) }

  it "returns 200 and enqueues ResultAvailableJob for a valid sample" do
    expect(Notifications::ResultAvailableJob).to receive(:perform_later).with(sample.Id)

    post "/masdiag/result_available/#{sample.Id}", headers: http_auth_header
    expect(response).to have_http_status(200)
  end

  it "returns 422 for an unknown sample" do
    expect(Notifications::ResultAvailableJob).not_to receive(:perform_later)

    post "/masdiag/result_available/999999", headers: http_auth_header
    expect(response).to have_http_status(422)
  end

  it "is blocked by MasdiagCheck for a non-institution-1 caller" do
    other_inst = create(:institution, id: 2)
    other_contractor = create(:contractor, institution_id: other_inst.id)
    create(:api_account, username: "other", password: "password", contractor_id: other_contractor.Id)

    header = { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("other", "password"),
               }
    post "/masdiag/result_available/#{sample.Id}", headers: header
    expect(response).to have_http_status(:unprocessable_content)
  end
end
