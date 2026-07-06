require 'rails_helper'

RSpec.describe 'Lalen::SampleController#update', type: :request do
  describe 'PUT /lalen/sample/update' do
    let!(:inst) { create(:institution, id: 83) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
    let!(:product) { create(:product) }
    let!(:package) { create(:package, product: product) }
    let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }

    def do_update(sample_collection_date:, code: "JV4XJ")
      put '/lalen/sample/update',
        params: { sample: { code: code, sample_collection_date: sample_collection_date } },
        headers: http_auth_header
    end

    context 'with valid parameters' do
      let!(:valid_sample) { create(:sample, Code: "JV4XJ") }

      it 'updates the sample_collection_date and returns 200' do
        new_date = Date.today - 1.day
        do_update(sample_collection_date: new_date)

        expect(response).to have_http_status(200)
        expect(valid_sample.reload.sample_collection_date.to_date).to eq(new_date)
      end
    end

    context 'when code was not found for your institution' do
      let!(:valid_sample) { create(:sample, Code: "JV4XJ") }

      it 'returns an error message' do
        rsc.update(InstitutionId: nil)
        do_update(sample_collection_date: Date.today)

        expect(json.dig("message")).to eq("A such sample code was not found for your institution.")
        expect(response).to have_http_status(422)
      end
    end

    context 'when the sample is already accepted in lab' do
      let!(:valid_sample) { create(:sample, Code: "JV4XJ", AcceptanceDate: Date.today) }

      it 'returns an error message' do
        do_update(sample_collection_date: Date.today)

        expect(json.dig("message")).to eq("This sample does not exist or cannot be modified.")
        expect(response).to have_http_status(422)
      end
    end

    context 'when the sample_collection_date is out of range' do
      let!(:valid_sample) { create(:sample, Code: "JV4XJ") }

      it 'returns validation errors for a future date' do
        do_update(sample_collection_date: Date.today + 1.day)

        expect(response).to have_http_status(422)
      end

      it 'returns validation errors for a date older than 6 weeks' do
        do_update(sample_collection_date: Date.today - 7.weeks)

        expect(response).to have_http_status(422)
      end
    end
  end
end
