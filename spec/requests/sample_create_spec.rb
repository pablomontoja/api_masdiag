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

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
      end

      it 'returns code and tests' do
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("sample", "code")).to eq("JV4XJ")
        expect(json.dig("sample", "tests")).to eq(rsc.projects_names)
        expect(response).to have_http_status(201)
      end

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
    end

    context 'with valid parameters but without pesel' do
      let!(:product) { create(:product) }
      let!(:project) { create(:project) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) { build(:sample_without_pesel)}

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
      end

      it 'returns code and tests' do
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("sample", "code")).to eq("JV4XJ")
        expect(json.dig("sample", "tests")).to eq(rsc.projects_names)
      end

      it 'returns a created status' do
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(response).to have_http_status(201)
      end
    end

    context 'with valid parameters but not assigned DBS' do
      let!(:product) { create(:product) }
      let!(:project) { create(:project) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:rsc_without_institution, package_id: package.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) { build(:sample_with_pesel)}

      it 'returns error message when DBS card not assigned' do
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to eq("A such sample code was not found for your institution.")
      end
    end

    context 'with invalid parameters' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:product) { create(:product) }
      let!(:project) { create(:project) }
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

      it 'returns error message when patient first_name is too short' do
        smp_params[:sample][:patient_attributes][:first_name] = "A"
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient firstname is too short")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient first_name is blank' do
        smp_params[:sample][:patient_attributes][:first_name] = ""
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient firstname can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient last_name is too short' do
        smp_params[:sample][:patient_attributes][:last_name] = "A"
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient lastname is too short")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient last_name is blank' do
        smp_params[:sample][:patient_attributes][:last_name] = ""
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient lastname can't be blank")
        expect(response).to have_http_status(422)
      end

      # Patient gender can't be blank, Patient birthdate can't be blank, Patient birthdate can't be blank, Patient id number can't be blank, Patient id number is too short

    end

    context 'with invalid parameters and without pesel' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:product) { create(:product) }
      let!(:project) { create(:project) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) { build(:sample_without_pesel)}

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
      end

      it 'returns error message when patient first_name is too short' do
        smp_params[:sample][:patient_attributes][:first_name] = "A"
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient firstname is too short")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient first_name is blank' do
        smp_params[:sample][:patient_attributes][:first_name] = ""
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient firstname can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient last_name is too short' do
        smp_params[:sample][:patient_attributes][:last_name] = "A"
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient lastname is too short")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient last_name is blank' do
        smp_params[:sample][:patient_attributes][:last_name] = ""
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient lastname can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient gender is blank' do
        smp_params[:sample][:patient_attributes][:gender] = ""
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient gender can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient birthdate is blank' do
        smp_params[:sample][:patient_attributes][:birth_date] = ""
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient birthdate can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient birthdate is blank' do
        smp_params[:sample][:patient_attributes][:id_number] = ""
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient id number can't be blank")
        expect(json.dig("message")).to include("Patient id number is too short")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient pesel is invalid' do
        smp_params[:sample][:patient_attributes][:pesel] = "12345"
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient pesel is invalid")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient id_document is invalid' do
        smp_params[:sample][:patient_attributes][:id_document] = 0
        post '/v1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("is not in the list of possible documents")
        expect(response).to have_http_status(422)
      end

    end



  end
end
