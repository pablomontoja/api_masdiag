require 'rails_helper'

# Smoke coverage — see spec/requests/regspec/institutions_spec.rb for rationale.
# specs/007-rails-72-upgrade/contracts/api-equivalence.md — SC-009.
#
# Only #update is routed for patients; #create is commented out in the
# controller and absent from config/routes.rb.
RSpec.describe 'Regspec::PatientsController', type: :request do
  let!(:masdiag)     { create(:institution, id: 1) }
  let!(:contractor)  { create(:contractor, institution_id: masdiag.id) }
  let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

  let!(:patient) { create(:patient, contractor: contractor) }

  let(:patient_payload) do
    {
      patient: {
        first_name: "Jan",
        last_name: "Kowalski",
        gender: 1,
        birth_date: "1980-01-15",
        pesel: "80011512345"
      }
    }
  end

  describe 'PATCH /regspec/patients/:id' do
    it 'updates the patient and returns an empty body' do
      patch "/regspec/patients/#{patient.Id}",
            params: patient_payload,
            headers: http_auth_header

      expect(response).to have_http_status(:ok)
      expect(json).to eq({})
      expect(patient.reload.FirstName).to eq("Jan")
      expect(patient.LastName).to eq("Kowalski")
    end

    it 'requires authentication' do
      patch "/regspec/patients/#{patient.Id}", params: patient_payload

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
