require 'rails_helper'
# include ApiHelpers

RSpec.describe 'Samples', type: :request do
  describe 'POST /create' do
    context 'with valid parameters' do
      # let!(:valid_sample) { FactoryBot.create(:sample) }
      let!(:product) { create(:product) }
      let!(:project) { create(:project) }
      let!(:package) { create(:package, product: product) }
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, package_id: package.id, InstitutionId: inst.id, IsRetailSale: true) }
      let!(:contractor) {create(:contractor, institution_id: inst.id)}
      let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
      let(:smp_params) {{
                          "sample": {
                            "code": "JV4XJ",
                            "sample_collection_date": "2022-04-10",
                            "patient_attributes": {
                              "email": "email@domain.com",
                              "first_name": "Paweł",
                              "last_name": "Świder",
                              "pesel": "73080335755",
                              "is_foreigner": false,
                              "birth_date": "",
                              "gender": "0",
                              "id_document": 0,
                              "id_number": "AA"
                            }
                          }
      }}

      it 'returns code and tests' do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)

        post '/v1/sample', params: smp_params, headers: {"Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("username","password")}

        pp response.body
        expect(json.dig("sample", "code")).to eq("JV4XJ")
        expect(json.dig("sample", "tests")).to eq(rsc.projects_names)

      end

      it 'returns a created status' do
        rsc.reserved_tests.create!(project_id: 2)
        rsc.update(IsRetailSale: true, InstitutionId: inst.id)
        post '/v1/sample', params: smp_params, headers: {"Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("username","password")}
        pp response.body
        expect(response).to have_http_status(201)
      end
    end

    # context 'with invalid parameters' do
    #   before do
    #     post '/api/v1/posts', params:
    #     { post: {
    #         title: '',
    #         content: ''
    #     } }
    #   end

    #   it 'returns a unprocessable entity status' do
    #     expect(response).to have_http_status(:unprocessable_entity)
    #   end
    # end
  end
end
# view raw
# post_posts_spec.rb hosted with ❤ by GitHub


# {
#   "sample": {
#     "id": 10,
#     "code": "2V6UP",
#     "tests": [
#       "Aminokwasy",
#       "Witamina A, E oraz Q10"
#     ]
#   }
# }
