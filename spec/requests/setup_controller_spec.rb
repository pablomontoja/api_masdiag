require 'rails_helper'
# include ApiHelpers

RSpec.describe 'V1::SetupController#result_post_endpoint', type: :request do
  describe 'POST /v1/setup/result_post_endpoint' do
    context 'with valid parameters' do
      let!(:inst) { create(:institution) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:valid_params) { build(:valid_setup_params)}

      it 'returns status 200' do
        post '/v1/setup/result_post_endpoint', params: valid_params, headers: http_auth_header
        expect(response).to have_http_status(200)
        expect(json.dig("current_result_post_endpoint_url")).to eq(valid_params.dig(:data, :url))
        expect(json.dig("current_result_post_endpoint_username")).to eq(valid_params.dig(:data, :username))
        expect(json.dig("current_result_post_endpoint_password")).to eq("*" * valid_params.dig(:data, :password).size)

      end

      it 'returns status 200 with blank username' do
        valid_params[:data][:username] = nil
        post '/v1/setup/result_post_endpoint', params: valid_params, headers: http_auth_header
        expect(response).to have_http_status(200)
        expect(json.dig("current_result_post_endpoint_url")).to eq(valid_params.dig(:data, :url))
        expect(json.dig("current_result_post_endpoint_username")).to eq(nil)
        expect(json.dig("current_result_post_endpoint_password")).to eq(nil)
      end


      it 'returns status 200 with blank password' do
        valid_params[:data][:password] = nil
        post '/v1/setup/result_post_endpoint', params: valid_params, headers: http_auth_header
        expect(response).to have_http_status(200)
        expect(json.dig("current_result_post_endpoint_url")).to eq(valid_params.dig(:data, :url))
        expect(json.dig("current_result_post_endpoint_username")).to eq(nil)
        expect(json.dig("current_result_post_endpoint_password")).to eq(nil)
      end
    end

    # context 'with invalid parameters' do
    #   let!(:valid_sample) { FactoryBot.create(:sample) }
    #   let!(:product) { create(:product) }
    #   let!(:project) { create(:project) }
    #   let!(:package) { create(:package, product: product) }
    #   let!(:inst) { create(:institution) }
    #   let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
    #   let!(:contractor) {create(:contractor, institution_id: inst.id)}
    #   let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
    #   let(:smp_params) { build(:sample_with_pesel)}

    #   before :each do
    #     rsc.reserved_tests.create!(project_id: 2)
    #     rsc.update(IsRetailSale: true, InstitutionId: inst.id)
    #   end

    #   it 'returns error message when code was not found for your institution' do
    #     rsc.update(InstitutionId: nil)
    #     delete '/v1/sample/delete/JV4XJ', headers: http_auth_header
    #     expect(json.dig("message")).to eq("A such sample code was not found for your institution.")
    #     expect(response).to have_http_status(422)
    #   end

    #   it 'returns error message when sample is accepted in lab' do
    #     valid_sample.update(AcceptanceDate: Date.today)
    #     delete '/v1/sample/delete/JV4XJ', headers: http_auth_header
    #     expect(json.dig("message")).to eq("This sample cannot be deleted.")
    #     expect(response).to have_http_status(422)
    #   end
    # end

    

  end
end
