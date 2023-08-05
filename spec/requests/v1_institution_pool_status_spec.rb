require 'rails_helper'
# include ApiHelpers

RSpec.describe 'V1::InstitutionController#pool_status', type: :request do
  describe 'GET /v1/institution/pool_status' do

    context 'with normal use' do
      let!(:inst) { create(:institution) }
      let!(:contractor) { create(:contractor, institution_id: inst.id) }
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

      it 'returns status 200' do
        get "/v1/institution/pool_status", headers: http_auth_header
        expect(response).to have_http_status(200)
      end

      it 'returns json with expected keys' do
        get "/v1/institution/pool_status", headers: http_auth_header
        expect(json).to have_key("available_tests")
        expect(json).to have_key("used_tests")
      end

    end

  end
end
