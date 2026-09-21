require "rails_helper"

RSpec.describe "GET /masdiag/labsample/latest_version", type: :request do
  let!(:inst) { create(:institution) }
  let!(:contractor) { create(:contractor, institution_id: inst.id) }
  let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

  it "returns 401 without Basic Auth" do
    get "/masdiag/labsample/latest_version"
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns a nil version when no release exists yet" do
    get "/masdiag/labsample/latest_version", headers: http_auth_header
    expect(response).to have_http_status(200)
    expect(json.dig("version")).to be_nil
  end

  it "returns the most recently created release's version" do
    create(:labsample_release, version: "2.9.11.9")
    create(:labsample_release, version: "2.9.11.10")

    get "/masdiag/labsample/latest_version", headers: http_auth_header
    expect(response).to have_http_status(200)
    expect(json.dig("version")).to eq("2.9.11.10")
  end
end
