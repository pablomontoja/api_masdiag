require 'rails_helper'
# include ApiHelpers

RSpec.describe 'Nume::KitController#check_code', type: :request do
  describe 'GET /nume/kits/check_code/:code' do

    context 'with valid and real sample code' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:project_vitd) { create(:project, Id: 2, eng_name: "Vitamin D metabolites") }
      let!(:project_aa) { create(:project, Id: 3, eng_name: "Aminoacids") }
      # let!(:measurement) { create(:measurement, sample: valid_sample, project: project) }
      let!(:product_plus) { create(:product, id: 15) }
      let!(:product_standard) { create(:second_product, id: 16) }
      let!(:package) { create(:package, product: product_plus) }
      let!(:inst) { create(:institution, name: "Nume") }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:assign_params) { build(:test_assignment)}

      before do
        rsc.reserved_tests.create(project_id: 2)
        rsc.reserved_tests.create(project_id: 3)
      end

      it 'returns status 200' do        
        get "/nume/kits/check_code/JV4XJ", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(200)
        expect(json.dig("test_ids")).to eq([2, 3])
        expect(json.dig("test_names")).to eq(["Vitamin D metabolites", "Aminoacids"])
        expect(json.dig("masdiag_check_sum")).to eq("ok")
        expect(json.dig("code")).to eq(rsc.Code)
        
      end

      it 'returns VITAMIN D PLUS kit_type' do
        get "/nume/kits/check_code/JV4XJ", params: assign_params, headers: http_auth_header
        expect(json.dig("kit_type")).to eq("VITAMIN D PLUS")
      end

      it 'returns VITAMIN D STANDARD kit_type' do
        package.update(product_id: 16)
        get "/nume/kits/check_code/JV4XJ", params: assign_params, headers: http_auth_header
        expect(json.dig("kit_type")).to eq("VITAMIN D STANDARD")
      end
    end

    context 'with unreal sample code' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:project_vitd) { create(:project, Id: 2, eng_name: "Vitamin D metabolites") }
      let!(:project_aa) { create(:project, Id: 3, eng_name: "Aminoacids") }
      # let!(:measurement) { create(:measurement, sample: valid_sample, project: project) }
      let!(:product) { create(:product) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution, name: "Nume") }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:assign_params) { build(:test_assignment)}

      before do
        rsc.reserved_tests.create(project_id: 2)
        rsc.reserved_tests.create(project_id: 3)
      end

      it 'returns status 422 for nume' do
        get "/nume/kits/check_code/ABCDE", params: assign_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("test_ids")).to eq(nil)
        expect(json.dig("test_names")).to eq(nil)
        expect(json.dig("masdiag_check_sum")).to eq("invalid")
        expect(json.dig("code")).to eq("ABCDE")
      end
    end

  end
end
