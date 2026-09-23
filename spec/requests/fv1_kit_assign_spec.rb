require 'rails_helper'
# include ApiHelpers

RSpec.describe 'Fv1::KitController#assign_tests', type: :request do
  describe 'POST /fv1/kits/assign_tests' do

    context 'with valid params' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
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

      it 'returns status 204' do
        post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end

      it 'returns status 204 for string array of test_ids' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=["2", "3"]}
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end      

      it 'changes number of institution_tests by 0' do
        expect {
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.count }.by(0)
        expect(response).to have_http_status(204)
      end      

      it 'changes number of reserved_tests by 2' do
        expect {
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
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
      let!(:not_registered_sample) { FactoryBot.create(:not_registered_sample_in_lab) }
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

      it 'returns status 204' do
        post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end

      it 'returns status 422 if IsWrongRegistration false' do
        not_registered_sample.update!(IsWrongRegistration: false)
        post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(422)
      end

      it 'returns status 204 for string array of test_ids' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=["2", "3"]}
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end      

      it 'changes number of institution_tests by 0' do
        expect {
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.count }.by(0)
        expect(response).to have_http_status(204)
      end      

      it 'changes number of reserved_tests by 2' do
        expect {
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
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


    context 'with valid params but RSC with nil package_id' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:project_vitd) { create(:project, Id: 2) }
      let!(:project_aa) { create(:project, Id: 3) }
      # let!(:measurement) { create(:measurement, sample: valid_sample, project: project) }
      let!(:inst) { create(:institution, name: "Nume") }
      let!(:rsc) { create(:reserved_sample_code, package_id: nil, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:assign_params) { build(:test_assignment)}

      it 'returns status 204' do
        post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
        expect(rsc.reserved_tests.count).to be(2)
        expect(response).to have_http_status(204)
      end
    end

    context 'omega acids remap for institutions 83 and 95' do
      let!(:project_omega_acids) { create(:project, Id: 21) }
      let!(:project_omega3_index) { create(:project, Id: 34) }
      let!(:product) { create(:product) }
      let!(:package) { create(:package, product: product) }
      let!(:contractor) { create(:contractor, institution_id: inst.id) }
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true, material_handler: :dbs_i4) }
      let(:assign_params) { { data: { code: rsc.Code, test_ids: [21] } } }

      context 'institution 83 (FFTB)' do
        let!(:inst) { create(:institution, id: 83, name: "Food for the brain") }

        it 'persists project 34 instead of the requested 21' do
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
          expect(response).to have_http_status(204)
          expect(rsc.reload.project_ids).to contain_exactly(34)
        end

        it 'still pushes the Lalen job using the original omega-3-complete key for project 21' do
          expect(LalenApi::AssignKitTestsJob).to receive(:perform_later).with(rsc.Code, ["omega-3-complete"])
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
          expect(response).to have_http_status(204)
        end
      end

      context 'institution 95' do
        let!(:inst) { create(:institution, id: 95, name: "Institution 95") }

        it 'persists project 34 instead of the requested 21' do
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
          expect(response).to have_http_status(204)
          expect(rsc.reload.project_ids).to contain_exactly(34)
        end
      end

      context 'other institutions' do
        let!(:inst) { create(:institution, name: "Nume") }

        it 'persists the requested project 21 unchanged' do
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
          expect(response).to have_http_status(204)
          expect(rsc.reload.project_ids).to contain_exactly(21)
        end
      end
    end

    context 'with invalid params' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:product) { create(:product) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution, name: "Nume") }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:assign_params) { build(:test_assignment)}

      it 'changes number of transactions by 0' do
        previous = TestTransaction.count
        post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
        current = TestTransaction.count
        expect(current - previous).to be(0)
        expect(response).to have_http_status(422)
      end

      it 'changes number of used institution_test by 0' do
        expect {
          post "/fv1/kits/assign_tests", params: assign_params, headers: http_auth_header
        }.to change { InstitutionTest.where(used: true).count }.by(0)
        expect(response).to have_http_status(422)
      end

      it 'returns error message when test_ids array is empty' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[]}
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("test_ids array can not be empty")
      end

      it 'returns error message when at least one test_id is not available' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[1]}
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("One or more tests can not be assigned")
      end

      it 'returns error message when two material type is mixed in test_ids' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 15]}
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("Assignment of tests for 2 different types of material is not possible")
      end

      it 'returns error when test 26 requested but material_handler is not dbs_i4' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3, 26]}
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("A Glutathione test can only be assigned to a special DBS sample collection card")
      end

      it 'returns error when test 26 requested but reserved_tests already exist' do
        project_any = create(:project, Id: 2)
        rsc_dbs_i4 = create(:reserved_sample_code, Code: "IAA4X", package_id: package.id, InstitutionId: inst.id, IsRetailSale: true, material_handler: :dbs_i4)
        rsc_dbs_i4.reserved_tests.create!(project_id: project_any.Id)
        tmp_params = { data: { code: rsc_dbs_i4.Code, test_ids: [26] } }
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("Tests for this sample collection card have already been assigned and cannot be changed")
      end

      it 'returns error when reassigning without test 26 but test 26 is already assigned' do
        project_26 = create(:project, Id: 26)
        project_12 = create(:project, Id: 12)
        rsc_dbs_i4 = create(:reserved_sample_code, Code: "IAA4Z", package_id: package.id, InstitutionId: inst.id, IsRetailSale: true, material_handler: :dbs_i4)
        rsc_dbs_i4.reserved_tests.create!(project_id: project_26.Id)
        tmp_params = { data: { code: rsc_dbs_i4.Code, test_ids: [12] } }

        expect {
          post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        }.not_to change { rsc_dbs_i4.reserved_tests.reload.pluck(:project_id) }

        expect(response).to have_http_status(422)
        expect(json.dig("message")).to eq("Tests for this sample collection card have already been assigned and cannot be changed")
      end

      it 'assigns test 26 successfully when material_handler is dbs_i4 and no existing tests' do
        project_26 = create(:project, Id: 26)
        rsc_dbs_i4 = create(:reserved_sample_code, Code: "IAA4Y", package_id: package.id, InstitutionId: inst.id, IsRetailSale: true, material_handler: :dbs_i4)
        tmp_params = { data: { code: rsc_dbs_i4.Code, test_ids: [26] } }
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header
        expect(response).to have_http_status(204)
      end

      it 'returns error message when code is not found for Institution' do
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3]}
        rsc.update(InstitutionId: nil)
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(json.dig("message")).to eq("A such sample code was not found for your institution")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when sample in lab is found' do
        valid_sample = FactoryBot.create(:sample)
        tmp_params = assign_params.tap{|prm| prm[:data][:test_ids]=[2, 3]}
        valid_sample.update(AcceptanceDate: 2.days.ago)
        post "/fv1/kits/assign_tests", params: tmp_params, headers: http_auth_header

        expect(json.dig("message")).to eq("Tests for this sample cannot be assigned")
        expect(response).to have_http_status(422)
      end
    end

  end
end
