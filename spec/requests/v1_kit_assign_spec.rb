require 'rails_helper'
# include ApiHelpers

RSpec.describe 'V1::KitController#assign_tests', type: :request do
  describe 'POST /v1/kits/assign_tests' do

    context 'with valid params' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
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

      before do
        TestTransaction.create(project_id: project_vitd.Id, amount_change: 2, contractor_id: contractor.Id)
        TestTransaction.create(project_id: project_aa.Id, amount_change: 2, contractor_id: contractor.Id)
      end

      it 'returns status 204' do
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end

      it 'returns status 204 for string array of test_ids' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=["2", "3"]}
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end

      it 'changes number of used institution_tests by 2' do
        expect {
          post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.where(used: true).count }.by(2)
        expect(response).to have_http_status(204)
      end

      it 'changes number of used institution_tests by 2 even if action is used multiple times' do
        prev = InstitutionTest.where(used: true).count
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        curr = InstitutionTest.where(used: true).count
        expect(curr - prev).to be(2)
        expect(response).to have_http_status(204)
      end

      it 'changes number of institution_tests by 0' do
        expect {
          post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.count }.by(0)
        expect(response).to have_http_status(204)
      end

      it 'changes number of transactions by 2' do
        previous = TestTransaction.count
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        current = TestTransaction.count
        expect(current - previous).to be(2)
        expect(response).to have_http_status(204)
      end

      it 'changes number of transactions by 6' do
        previous = TestTransaction.count
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        current = TestTransaction.count
        expect(current - previous).to be(6)
        expect(response).to have_http_status(204)
      end

      it 'changes number of reserved_tests by 2' do
        expect {
          post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { ReservedTest.where(reserved_sample_code_id: rsc.Id).count }.by(2)
        expect(response).to have_http_status(204)
      end

      it 'override assignment if assigned' do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.reserved_tests.create!(project_id: 3)
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2]}
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(rsc.reserved_tests.count).to be(1)
        expect(rsc.project_ids).to include(2)
        expect(rsc.project_ids).not_to include(3)
      end
    end

    context 'with valid params but not registered sample' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:not_registered_sample) { FactoryBot.create(:not_registered_sample_in_lab) }
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

      before do
        TestTransaction.create(project_id: project_vitd.Id, amount_change: 2, contractor_id: contractor.Id)
        TestTransaction.create(project_id: project_aa.Id, amount_change: 2, contractor_id: contractor.Id)
      end

      it 'returns status 204' do
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end

      it 'returns status 422 if IsWrongRegistration false' do
        not_registered_sample.update!(IsWrongRegistration: false)
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(422)
      end

      it 'returns status 204 for string array of test_ids' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=["2", "3"]}
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end

      it 'changes number of used institution_tests by 2' do
        expect {
          post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.where(used: true).count }.by(2)
        expect(response).to have_http_status(204)
      end

      it 'changes number of used institution_tests by 2 even if action is used multiple times' do
        prev = InstitutionTest.where(used: true).count
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        curr = InstitutionTest.where(used: true).count
        expect(curr - prev).to be(2)
        expect(response).to have_http_status(204)
      end

      it 'changes number of institution_tests by 0' do
        expect {
          post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.count }.by(0)
        expect(response).to have_http_status(204)
      end

      it 'changes number of transactions by 2' do
        previous = TestTransaction.count
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        current = TestTransaction.count
        expect(current - previous).to be(2)
        expect(response).to have_http_status(204)
      end

      it 'changes number of transactions by 6' do
        previous = TestTransaction.count
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        current = TestTransaction.count
        expect(current - previous).to be(6)
        expect(response).to have_http_status(204)
      end

      it 'changes number of reserved_tests by 2' do
        expect {
          post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { ReservedTest.where(reserved_sample_code_id: rsc.Id).count }.by(2)
        expect(response).to have_http_status(204)
      end

      it 'override assignment if assigned' do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.reserved_tests.create!(project_id: 3)
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2]}
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(rsc.reserved_tests.count).to be(1)
        expect(rsc.project_ids).to include(2)
        expect(rsc.project_ids).not_to include(3)
      end
    end

    context 'with invalid params' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
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

      # before do
      #   TestTransaction.create(project_id: project_vitd.Id, amount_change: 2, contractor_id: contractor.Id)
      #   TestTransaction.create(project_id: project_aa.Id, amount_change: 2, contractor_id: contractor.Id)
      # end

      it 'returns status 422 due to lack of tests in pool' do
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to match(/not enough institution tests left in pool for such assignment/)
      end

      it 'changes number of transactions by 0' do
        previous = TestTransaction.count
        post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        current = TestTransaction.count
        expect(current - previous).to be(0)
        expect(response).to have_http_status(422)
      end

      it 'changes number of used institution_test by 0' do
        expect {
          post "/v1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.where(used: true).count }.by(0)
        expect(response).to have_http_status(422)
      end

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

      it 'returns error when test 26 requested but material_handler is not dbs_i4' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3, 26]}
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("Test 26 can only be assigned to a dbs_i4 material handler")
      end

      it 'returns error when test 26 requested but reserved_tests already exist' do
        rsc_dbs_i4 = create(:reserved_sample_code, Code: "IAA4X", package_id: package.id, InstitutionId: inst.id, IsRetailSale: true, material_handler: :dbs_i4)
        rsc_dbs_i4.reserved_tests.create!(project_id: 2)
        tmp_params = { data: { code: rsc_dbs_i4.Code, test_ids: [26] } }
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("Tests for this sample collection card have already been assigned and cannot be changed")
      end

      it 'assigns test 26 successfully when material_handler is dbs_i4 and no existing tests' do
        project_26 = create(:project, Id: 26)
        rsc_dbs_i4 = create(:reserved_sample_code, Code: "IAA4Y", package_id: package.id, InstitutionId: inst.id, IsRetailSale: true, material_handler: :dbs_i4)
        TestTransaction.create(project_id: project_26.Id, amount_change: 2, contractor_id: contractor.Id)
        tmp_params = { data: { code: rsc_dbs_i4.Code, test_ids: [26] } }
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end

      it 'returns error message when code is not found for Institution' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3]}
        rsc.update(InstitutionId: nil)
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(json.dig("message")).to eq("A such sample code was not found for your institution")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when sample in lab is found' do
        valid_sample = FactoryBot.create(:sample)
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3]}
        valid_sample.update(AcceptanceDate: 2.days.ago)
        post "/v1/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(json.dig("message")).to eq("Tests for this sample cannot be assigned")
        expect(response).to have_http_status(422)
      end
    end

  end
end
