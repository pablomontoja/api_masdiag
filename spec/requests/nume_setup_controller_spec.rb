require 'rails_helper'
# include ApiHelpers

RSpec.describe 'Nume::SetupController#result_post_endpoint', type: :request do
  describe 'POST /nume/setup/result_post_endpoint' do
    context 'with valid parameters' do
      let!(:inst) { create(:institution, name: "Nume") }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:valid_params) { build(:valid_setup_params)}

      it 'returns status 200' do
        post '/nume/setup/result_post_endpoint', params: valid_params, headers: http_auth_header
        expect(response).to have_http_status(200)
        expect(json.dig("current_result_post_endpoint_url")).to eq(valid_params.dig(:data, :url))
        expect(json.dig("current_result_post_endpoint_username")).to eq(valid_params.dig(:data, :username))
        expect(json.dig("current_result_post_endpoint_password")).to eq("*" * valid_params.dig(:data, :password).size)

      end

      it 'returns status 200 with blank username' do
        valid_params[:data][:username] = nil
        post '/nume/setup/result_post_endpoint', params: valid_params, headers: http_auth_header
        expect(response).to have_http_status(200)
        expect(json.dig("current_result_post_endpoint_url")).to eq(valid_params.dig(:data, :url))
        expect(json.dig("current_result_post_endpoint_username")).to eq(nil)
        expect(json.dig("current_result_post_endpoint_password")).to eq(nil)
      end


      it 'returns status 200 with blank password' do
        valid_params[:data][:password] = nil
        post '/nume/setup/result_post_endpoint', params: valid_params, headers: http_auth_header
        expect(response).to have_http_status(200)
        expect(json.dig("current_result_post_endpoint_url")).to eq(valid_params.dig(:data, :url))
        expect(json.dig("current_result_post_endpoint_username")).to eq(nil)
        expect(json.dig("current_result_post_endpoint_password")).to eq(nil)
      end
    end  

  end
end
