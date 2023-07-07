require 'rails_helper'
# include ApiHelpers

RSpec.describe 'V1::SampleController#create', type: :request do
  describe 'POST /v1/sample' do
    context 'with valid parameters' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:product) { create(:product) }
      let!(:project) { create(:project) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) { build(:sample_with_pesel)}
      let!(:sample) { create(:sample, IsWrongRegistration: true) }

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
      end

      it 'returns code and tests' do
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("sample", "code")).to eq("JV4XJ")
        expect(json.dig("sample", "tests")).to eq(rsc.projects_names)
        expect(response).to have_http_status(201)
        expect(Sample.count).to eql(1)
      end

      it 'uses WrongSampleUpdater as sample creator' do
        expect(V1::WrongSampleUpdater).to receive(:call).and_call_original
        expect(V1::SampleCreator).not_to receive(:call).and_call_original

        post '/v1/sample', params: smp_params, headers: http_auth_header
      end

      # it 'modifies the parameters of the sample as appropriate' do        
      #   expect(assigns(:sample).RegistrationDate).not_to eql(nil)
      #   expect(assigns(:sample).PatientId).not_to eql(nil)
      #   expect(assigns(:sample).IsWrongRegistration).to eql(false)
      #   expect(assigns(:sample).WasWrongRegistration).to eql(true)
      #   expect(assigns(:sample).WrongRegistrationStatus).to eql(2)
      #   expect(assigns(:sample).measurements.count).to eql(1)
      #   expect(assigns(:sample).WrongRegistrationStatus).to be_in([2, 4])
      # end

      it 'returns error message when DBS is expired' do
        rsc.update(expiry_date: 2.days.ago)
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to eq("The DBS card is expired.")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when DBS is not assigned' do
        rsc.reserved_tests.destroy_all
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to eq("The sample does not have assigned tests.")
        expect(response).to have_http_status(422)
      end

      it 'returns json with expected keys' do
        post "/v1/sample", params: smp_params, headers: http_auth_header
        expect(json.dig("sample")).to have_key("code")
        expect(json.dig("sample")).to have_key("tests")
        expect(json.dig("sample")).to have_key("id")
        expect(response).to have_http_status(201)
      end

      it 'returns a created status' do
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(response).to have_http_status(201)
      end

      it 'does not change amount of used institution_tests' do
        prev = InstitutionTest.where(used: true).count
        post '/v1/sample', params: smp_params, headers: http_auth_header
        curr = InstitutionTest.where(used: true).count
        expect(curr - prev).to be(0)
        expect(response).to have_http_status(201)
      end

      it 'sets patient language properly' do
        api_account.update(language: "de")
        post '/v1/sample', params: smp_params, headers: http_auth_header

        expect(@controller.instance_variable_get(:@sample).patient.language).to eq("de")
      end
    end

   



  end
end
