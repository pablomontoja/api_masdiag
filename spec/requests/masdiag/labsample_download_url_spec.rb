require "rails_helper"

RSpec.describe "GET /masdiag/labsample/download_url", type: :request do
  let!(:inst) { create(:institution) }
  let!(:contractor) { create(:contractor, institution_id: inst.id) }
  let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

  it "returns 401 without Basic Auth" do
    get "/masdiag/labsample/download_url"
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns a nil url when no release exists yet" do
    get "/masdiag/labsample/download_url", headers: http_auth_header
    expect(response).to have_http_status(200)
    expect(json.dig("url")).to be_nil
  end

  it "returns a nil url when the latest release has no archive attached" do
    create(:labsample_release, version: "2.9.11.10")

    get "/masdiag/labsample/download_url", headers: http_auth_header
    expect(response).to have_http_status(200)
    expect(json.dig("url")).to be_nil
  end

  it "returns a downloadable url when the latest release has an archive attached" do
    release = create(:labsample_release, version: "2.9.11.10")
    release.archive.attach(
      io: StringIO.new("fake 7z content"),
      filename: "LabSample-2.9.11.10.7z",
      content_type: "application/x-7z-compressed"
    )

    get "/masdiag/labsample/download_url", headers: http_auth_header
    expect(response).to have_http_status(200)
    expect(json.dig("url")).to be_present
    expect(json.dig("url")).to include("LabSample-2.9.11.10.7z")
  end
end
