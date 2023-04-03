require 'rails_helper'
# include ApiHelpers

RSpec.describe 'V1::KitController#assign_tests', type: :request do
  describe 'POST /v1/kits/assign_tests' do

    context 'with valid params' do
      let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:project_vitd) { create(:project, Id: 2) }
      let!(:project_aa) { create(:project, Id: 3) }
      # let!(:measurement) { create(:measurement, sample: valid_sample, project: project) }
      let!(:product) { create(:product) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:assign_params) { build(:test_assignment)}

      it 'returns status 204' do
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end
    end

    context 'with invalid params' do
      let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:project_vitd) { create(:project, Id: 2) }
      let!(:project_aa) { create(:project, Id: 3) }
      # let!(:measurement) { create(:measurement, sample: valid_sample, project: project) }
      let!(:product) { create(:product) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:assign_params) { build(:test_assignment)}

      it 'returns error message when test_ids array is empty' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[]}
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("test_ids array can not be empty")
      end

      it 'returns error message when at least one test_id is not available' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[1]}
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("One or more tests can not be assigned")
      end

      it 'returns error message when two material type is mixed in test_ids' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 15]}
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("Assignment of tests for 2 different types of material is not possible")
      end

      it 'returns error message when weight limit exceeded for DBS material' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3, 14]}
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("Weight limit exceeded for DBS material")
      end

      it 'returns error message when code is not found for Institution' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3]}
        rsc.update(InstitutionId: nil)
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(json.dig("message")).to eq("A such sample code was not found for your institution")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when sample in lab is found' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3]}
        valid_sample.update(AcceptanceDate: 2.days.ago)
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(json.dig("message")).to eq("Tests for this sample cannot be assigned")
        expect(response).to have_http_status(422)
      end
    end

  end
end
