require 'rails_helper'
# include ApiHelpers

RSpec.describe 'Nume::KitController#assign_tests', type: :request do
  describe 'POST /nume/kits/assign_tests' do

    context 'with valid params' do
      let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:project_vitd) { create(:project, Id: 2) }
      let!(:project_aa) { create(:project, Id: 3) }
      # let!(:measurement) { create(:measurement, sample: valid_sample, project: project) }
      let!(:product) { create(:product) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution, name: "Nume") }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:assign_params) { build(:test_assignment)}

      # before do
      #   TestTransaction.create(project_id: project_vitd.Id, amount_change: 2, contractor_id: contractor.Id)
      #   TestTransaction.create(project_id: project_aa.Id, amount_change: 2, contractor_id: contractor.Id)
      # end

      it 'returns status 204' do
        post "/nume/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end

      it 'returns status 204 for string array of test_ids' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=["2", "3"]}
        post "/nume/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end      

      it 'changes number of institution_tests by 0' do
        expect {
          post "/nume/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.count }.by(0)
        expect(response).to have_http_status(204)
      end      

      it 'changes number of reserved_tests by 2' do
        expect {
          post "/nume/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { ReservedTest.where(reserved_sample_code_id: rsc.Id).count }.by(2)
        expect(response).to have_http_status(204)
      end
    end

    context 'with invalid params' do
      let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:product) { create(:product) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution, name: "Nume") }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:assign_params) { build(:test_assignment)}

      it 'changes number of transactions by 0' do
        previous = TestTransaction.count
        post "/nume/kits/assign_tests", params: assign_params, headers: http_auth_header
        current = TestTransaction.count
        expect(current - previous).to be(0)
        expect(response).to have_http_status(422)
      end

      it 'changes number of used institution_test by 0' do
        expect {
          post "/nume/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.where(used: true).count }.by(0)
        expect(response).to have_http_status(422)
      end

      it 'returns error message when test_ids array is empty' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[]}
        post "/nume/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("test_ids array can not be empty")
      end

      it 'returns error message when at least one test_id is not available' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[1]}
        post "/nume/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("One or more tests can not be assigned")
      end

      it 'returns error message when two material type is mixed in test_ids' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 15]}
        post "/nume/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("Assignment of tests for 2 different types of material is not possible")
      end

      it 'returns error message when weight limit exceeded for DBS material' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3, 14]}
        post "/nume/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("Weight limit exceeded for DBS material")
      end

      it 'returns error message when code is not found for Institution' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3]}
        rsc.update(InstitutionId: nil)
        post "/nume/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(json.dig("message")).to eq("A such sample code was not found for your institution")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when sample in lab is found' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3]}
        valid_sample.update(AcceptanceDate: 2.days.ago)
        post "/nume/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(json.dig("message")).to eq("Tests for this sample cannot be assigned")
        expect(response).to have_http_status(422)
      end
    end

  end
end
