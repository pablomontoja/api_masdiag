require 'rails_helper'

RSpec.describe 'Lalen::SampleController#create', type: :request do
  describe 'POST /lalen/sample' do
    context 'with invalid sample_collection_date' do
      let!(:product) { create(:product) }
      let!(:project) { create(:project) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution, id: V1::Common::LALEN_INSTITUTION_IDS.first) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) { create(:contractor, institution_id: inst.id) }
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) { build(:sample_foreigner) }

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
      end

      it 'returns 422 with a validation message when sample_collection_date is in the future' do
        smp_params[:sample][:sample_collection_date] = 1.day.from_now.to_date.to_s
        post '/lalen/sample', params: smp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message", "sample_collection_date").join).to include("must be less than or equal to")
      end

      it 'returns 422 with a validation message when sample_collection_date is older than 6 weeks' do
        smp_params[:sample][:sample_collection_date] = 7.weeks.ago.to_date.to_s
        post '/lalen/sample', params: smp_params, headers: http_auth_header
        expect(response).to have_http_status(422)
        expect(json.dig("message", "sample_collection_date").join).to include("must be greater than or equal to")
      end
    end
  end
end
