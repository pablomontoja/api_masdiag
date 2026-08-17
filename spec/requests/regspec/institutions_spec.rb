require 'rails_helper'

# Smoke coverage for the regspec namespace, which had no request specs before
# the Rails 7.2 upgrade. These assert status and body shape only — enough to
# detect a response-contract change across the upgrade, not full behavioural
# coverage of the namespace.
#
# See specs/007-rails-72-upgrade/contracts/api-equivalence.md — SC-009.
RSpec.describe 'Regspec::InstitutionsController', type: :request do
  # Regspec controllers include MasdiagCheck: only institution 1 may call them.
  let!(:masdiag)       { create(:institution, id: 1) }
  let!(:contractor)    { create(:contractor, institution_id: masdiag.id) }
  let!(:api_account)   { create(:api_account, contractor_id: contractor.Id) }

  let(:institution_payload) do
    {
      institution: {
        name: "Szpital Testowy",
        street_address: "ul. Testowa 1",
        postal_code: "00-001",
        city: "Warszawa",
        nip: "5222996468"
      }
    }
  end

  describe 'POST /regspec/institutions' do
    it 'creates the institution and returns its id' do
      post '/regspec/institutions', params: institution_payload, headers: http_auth_header

      expect(response).to have_http_status(:created)
      expect(json).to have_key('institution_id')
      expect(json['institution_id']).to be_a(Integer)
    end

    it 'rejects a caller from another institution' do
      other_institution = create(:institution, name: "Inny Szpital")
      other_contractor  = create(:contractor, institution_id: other_institution.id)
      create(:api_account, contractor_id: other_contractor.Id,
                           username: "other", password: "otherpass")

      other_header = {
        "Authorization" =>
          ActionController::HttpAuthentication::Basic
            .encode_credentials("other", "otherpass")
      }

      post '/regspec/institutions', params: institution_payload, headers: other_header

      expect(response).to have_http_status(:unprocessable_content)
      expect(json['message']).to match(/do not have access/i)
    end

    it 'requires authentication' do
      post '/regspec/institutions', params: institution_payload

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /regspec/institutions/:id' do
    let!(:target) { create(:institution, name: "Przed zmianą") }

    it 'updates the institution and returns an empty body' do
      patch "/regspec/institutions/#{target.id}",
            params: institution_payload,
            headers: http_auth_header

      expect(response).to have_http_status(:ok)
      expect(json).to eq({})
      expect(target.reload.name).to eq("Szpital Testowy")
    end

    it 'requires authentication' do
      patch "/regspec/institutions/#{target.id}", params: institution_payload

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
