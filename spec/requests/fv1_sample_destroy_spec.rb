require 'rails_helper'
# include ApiHelpers

RSpec.describe 'Fv1::SampleController#delete', type: :request do
  describe 'DELETE /fv1/sample/:code' do
    context 'with invalid parameters' do
      let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:product) { create(:product) }
      let!(:project) { create(:project) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) { build(:sample_foreigner)}

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
      end

      it 'returns error message when code was not found for your institution' do
        rsc.update(InstitutionId: nil)
        delete '/fv1/sample/delete/JV4XJ', headers: http_auth_header
        expect(json.dig("message")).to eq("A such sample code was not found for your institution.")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when sample is accepted in lab' do
        valid_sample.update(AcceptanceDate: Date.today)
        delete '/fv1/sample/delete/JV4XJ', headers: http_auth_header
        expect(json.dig("message")).to eq("This sample cannot be deleted.")
        expect(response).to have_http_status(422)
      end
    end

    context 'with valid parameters' do
      let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:product) { create(:product) }
      let!(:project) { create(:project) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) { build(:sample_foreigner)}

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
      end

      it 'returns status 204' do
        delete '/fv1/sample/delete/JV4XJ', headers: http_auth_header
        expect(response).to have_http_status(204)
      end
    end

  end
end
