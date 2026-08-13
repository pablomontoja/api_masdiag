require 'rails_helper'

RSpec.describe 'Lalen::KitController', type: :request do
  let!(:project_omega_acids) { create(:project, Id: 21) }
  let!(:project_omega3_index) { create(:project, Id: 34) }
  let!(:product) { create(:product) }
  let!(:package) { create(:package, product: product) }
  let!(:auth_inst) { create(:institution, id: 83, name: "Food for the brain") }
  let!(:contractor) { create(:contractor, institution_id: auth_inst.id) }
  let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

  describe 'POST /lalen/kits/assign_tests' do
    let!(:rsc) { create(:reserved_sample_code, Code: "GB1234", package_id: package.id, InstitutionId: V1::Common::LALEN_INSTITUTION_IDS.first) }

    it 'remaps project 21 to 34 for a GB barcode (institution 83)' do
      params = { data: { code: "GB1234", test_ids: [21] } }
      post "/lalen/kits/assign_tests", params: params, headers: http_auth_header
      expect(response).to have_http_status(204)
      expect(rsc.reload.project_ids).to contain_exactly(34)
      expect(rsc.InstitutionId).to eq(83)
    end

    it 'does not remap other projects' do
      project_vitd = create(:project, Id: 2)
      params = { data: { code: "GB1234", test_ids: [2] } }
      post "/lalen/kits/assign_tests", params: params, headers: http_auth_header
      expect(response).to have_http_status(204)
      expect(rsc.reload.project_ids).to contain_exactly(2)
    end
  end

  describe 'POST /lalen/kits/declare' do
    before do
      User.create!(Id: 1, Login: "admin", Password: "x", Salt: "x", IsActive: true, Role: 0, HasSmartCard: false)
    end

    it 'remaps project 21 to 34 for a GB barcode (institution 83)' do
      params = { code: "GBDECLARE1", expiry_date: 1.year.from_now.to_date.to_s, material_handler: "dbs_faps", test_ids: [21] }
      post "/lalen/kits/declare", params: params, headers: http_auth_header
      expect(response).to have_http_status(201)
      rsc = ReservedSampleCode.find_by(Code: "GBDECLARE1")
      expect(rsc.project_ids).to contain_exactly(34)
      expect(rsc.InstitutionId).to eq(83)
    end
  end
end
