require 'rails_helper'
# include ApiHelpers

RSpec.describe 'V1::ResultController#show', type: :request do
  describe 'GET /v1/result/get/:code' do

    context 'with valid parameters' do
      let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:project) { create(:project) }
      let!(:measurement) { create(:measurement, sample: valid_sample, project: project) }
      let!(:product) { create(:product) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) { build(:sample_with_pesel)}

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)

        generate_results(codes: [valid_sample.Code])
      end

      it 'returns status 200' do
        get "/v1/result/get/#{valid_sample.Code}", headers: http_auth_header
        expect(response).to have_http_status(200)
      end

      it 'returns sample_code and test name' do
        get "/v1/result/get/#{valid_sample.Code}", headers: http_auth_header
        expect(json.dig("results").first["sample_code"]).to eq("JV4XJ")
        expect(json.dig("results").first["test"]).to eq(measurement.project.eng_name)
        expect(json.dig("results").first["unencrypted_result"]).not_to be_nil
      end

      it 'returns json with expected keys' do
        get "/v1/result/get/#{valid_sample.Code}", headers: http_auth_header
        expect(json.dig("results").size).to eq(1)
        expect(json.dig("results").first).to have_key("sample_code")
        expect(json.dig("results").first).to have_key("test")
        expect(json.dig("results").first).to have_key("measurement_status")
        expect(json.dig("results").first).to have_key("sample_status")
        expect(json.dig("results").first).to have_key("unencrypted_result")
        expect(json.dig("results").first).not_to have_key("rejection_reason")
        expect(json.dig("results").first).to have_key("raw_result")
      end

      it 'returns json with expected keys for cancelled sample' do
        valid_sample.update(SampleStatus: 4)
        get "/v1/result/get/#{valid_sample.Code}", headers: http_auth_header
        expect(json.dig("results").first["sample_status"]).to eq("cancelled")
        expect(json.dig("results").first).not_to have_key("unencrypted_result")
        expect(json.dig("results").first).to have_key("rejection_reason")
      end
    end

    context 'with invalid parameters' do
      let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:project) { create(:project) }
      let!(:measurement) { create(:measurement, sample: valid_sample, project: project) }
      let!(:product) { create(:product) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) { build(:sample_with_pesel)}

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
      end

      it 'returns error message when code is not found for Institution' do
        rsc.update(InstitutionId: nil)
        get "/v1/result/get/#{valid_sample.Code}", headers: http_auth_header
        expect(json.dig("message")).to eq("A such sample code was not found for your institution.")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when sample is not found' do
        valid_sample.destroy
        get "/v1/result/get/#{valid_sample.Code}", headers: http_auth_header
        expect(json.dig("message")).to eq("Unknown sample code or sample does not exist.")
        expect(response).to have_http_status(422)
      end
    end

  end
end
