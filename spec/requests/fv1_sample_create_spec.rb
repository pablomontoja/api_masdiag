require 'rails_helper'
# include ApiHelpers

RSpec.describe 'Fv1::SampleController#create', type: :request do
  describe 'POST /fv1/sample' do
    context 'with valid parameters' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
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

      it 'returns code and tests' do
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("sample", "code")).to eq("JV4XJ")
        expect(json.dig("sample", "tests")).to eq(rsc.projects_names)
        expect(response).to have_http_status(201)
      end

      it 'uses SampleCreator as sample creator' do
        expect(V1::WrongSampleUpdater).not_to receive(:call).and_call_original
        expect(V1::SampleCreator).to receive(:call).and_call_original

        post '/fv1/sample', params: smp_params, headers: http_auth_header
      end

      it 'returns error message when DBS is expired' do
        rsc.update(expiry_date: 2.days.ago)
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to eq("The DBS card is expired.")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when DBS is not assigned' do
        rsc.reserved_tests.destroy_all
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to eq("The sample does not have assigned tests.")
        expect(response).to have_http_status(422)
      end

      it 'returns json with expected keys' do
        post "/fv1/sample", params: smp_params, headers: http_auth_header
        expect(json.dig("sample")).to have_key("code")
        expect(json.dig("sample")).to have_key("tests")
        expect(json.dig("sample")).to have_key("id")
        expect(response).to have_http_status(201)
      end

      it 'returns a created status' do
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(response).to have_http_status(201)
      end

      it 'does not change amount of used institution_tests' do
        prev = InstitutionTest.where(used: true).count
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        curr = InstitutionTest.where(used: true).count
        expect(curr - prev).to be(0)
        expect(response).to have_http_status(201)
      end

      it "sets patient's language properly" do
        smp_params.tap{|h| h[:sample][:patient_attributes][:language] = "de"}
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(@controller.instance_variable_get(:@sample).patient.language).to eq("de")
      end

      it 'sets patient default language if the attribute is not present in params' do
        api_account.update(language: "de")
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(@controller.instance_variable_get(:@sample).patient.language).to eq("de")
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
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("sample", "code")).to eq("JV4XJ")
        expect(json.dig("sample", "tests")).to eq(rsc.projects_names)
      end

      it 'returns a created status' do
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(response).to have_http_status(201)
      end

      it "sets patient's language properly" do
        smp_params.tap{|h| h[:sample][:patient_attributes][:language] = "de"}
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(@controller.instance_variable_get(:@sample).patient.language).to eq("de")
      end   

      it 'sets patient default language if the attribute is not present in params' do
        api_account.update(language: "de")
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(@controller.instance_variable_get(:@sample).patient.language).to eq("de")
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
      let(:smp_params) { build(:sample_foreigner)}

      it 'returns error message when DBS card not assigned' do
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to eq("A such sample code was not found for your institution.")
      end

      it 'does not change amount of used institution_tests' do
        prev = InstitutionTest.where(used: true).count
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        curr = InstitutionTest.where(used: true).count
        expect(curr - prev).to be(0)
        expect(response).to have_http_status(422)
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
      let(:smp_params) { build(:sample_foreigner)}

      before :each do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
      end

      it 'returns error message when patient first_name is too short' do
        smp_params[:sample][:patient_attributes][:first_name] = "A"
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient firstname is too short")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient first_name is blank' do
        smp_params[:sample][:patient_attributes][:first_name] = ""
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient firstname can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient last_name is too short' do
        smp_params[:sample][:patient_attributes][:last_name] = "A"
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient lastname is too short")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient last_name is blank' do
        smp_params[:sample][:patient_attributes][:last_name] = ""
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient lastname can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'does not change amount of used institution_tests' do
        smp_params[:sample][:patient_attributes][:last_name] = ""
        smp_params[:sample][:patient_attributes][:first_name] = ""
        prev = InstitutionTest.where(used: true).count
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        curr = InstitutionTest.where(used: true).count
        expect(curr - prev).to be(0)
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient first_name is too short' do
        smp_params[:sample][:patient_attributes][:first_name] = "A"
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient firstname is too short")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient first_name is blank' do
        smp_params[:sample][:patient_attributes][:first_name] = ""
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient firstname can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient last_name is too short' do
        smp_params[:sample][:patient_attributes][:last_name] = "A"
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient lastname is too short")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient last_name is blank' do
        smp_params[:sample][:patient_attributes][:last_name] = ""
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient lastname can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient gender is blank' do
        smp_params[:sample][:patient_attributes][:gender] = ""
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient gender can't be blank")
        expect(response).to have_http_status(422)
      end

      it 'returns error message when patient birthdate is blank' do
        smp_params[:sample][:patient_attributes][:birth_date] = ""
        post '/fv1/sample', params: smp_params, headers: http_auth_header
        expect(json.dig("message")).to include("Patient birthdate can't be blank")
        expect(response).to have_http_status(422)
      end
    end



  end
end
