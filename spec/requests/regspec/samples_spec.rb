require 'rails_helper'

# Smoke coverage — see spec/requests/regspec/institutions_spec.rb for rationale.
# specs/007-rails-72-upgrade/contracts/api-equivalence.md — SC-009.
#
# Deliberately shallow. Regspec::SamplesController#create delegates to
# V1::SampleCreator and needs a full sample payload; building one here would
# duplicate the existing sample-creation specs without adding upgrade signal.
# What matters for the upgrade is that the namespace's auth and error
# contracts are unchanged, which is what these assert.
RSpec.describe 'Regspec::SamplesController', type: :request do
  let!(:masdiag)     { create(:institution, id: 1) }
  let!(:contractor)  { create(:contractor, institution_id: masdiag.id) }
  let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

  describe 'POST /regspec/samples' do
    it 'requires authentication' do
      post '/regspec/samples', params: { sample: { code: "JV4XJ" } }

      expect(response).to have_http_status(:unauthorized)
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

      post '/regspec/samples',
           params: { sample: { code: "JV4XJ", acceptance_date: Time.zone.today.to_s } },
           headers: other_header

      expect(response).to have_http_status(:unprocessable_content)
      expect(json['message']).to match(/do not have access/i)
    end
  end

  describe 'PATCH /regspec/samples/:id' do
    let!(:sample) { create(:sample) }

    it 'requires authentication' do
      patch "/regspec/samples/#{sample.Id}", params: { sample: { remarks: "x" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
