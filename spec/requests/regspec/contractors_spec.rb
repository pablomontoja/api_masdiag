require 'rails_helper'

# Smoke coverage — see spec/requests/regspec/institutions_spec.rb for rationale.
# specs/007-rails-72-upgrade/contracts/api-equivalence.md — SC-009.
RSpec.describe 'Regspec::ContractorsController', type: :request do
  let!(:masdiag)     { create(:institution, id: 1) }
  let!(:contractor)  { create(:contractor, institution_id: masdiag.id) }
  let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

  let!(:target_institution) { create(:institution, name: "Szpital Docelowy") }

  let(:contractor_payload) do
    {
      contractor: {
        name: "Oddział Testowy",
        email: "oddzial@example.test",
        institution_id: target_institution.id
      }
    }
  end

  describe 'POST /regspec/contractors' do
    it 'creates the contractor and returns its id' do
      post '/regspec/contractors', params: contractor_payload, headers: http_auth_header

      expect(response).to have_http_status(:created)
      expect(json).to have_key('contractor_id')
      expect(json['contractor_id']).to be_a(Integer)
    end

    it 'requires authentication' do
      post '/regspec/contractors', params: contractor_payload

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /regspec/contractors/:id' do
    let!(:target) do
      create(:contractor, institution_id: target_institution.id,
                          first_name: "Przed", email: "przed@example.test")
    end

    it 'updates the contractor and returns an empty body' do
      patch "/regspec/contractors/#{target.Id}",
            params: contractor_payload,
            headers: http_auth_header

      expect(response).to have_http_status(:ok)
      expect(json).to eq({})
      expect(target.reload.first_name).to eq("Oddział Testowy")
    end

    it 'requires authentication' do
      patch "/regspec/contractors/#{target.Id}", params: contractor_payload

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
