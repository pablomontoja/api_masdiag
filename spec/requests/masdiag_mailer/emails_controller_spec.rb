# require 'rails_helper'
# require 'rspec/json_expectations'

# RSpec.describe MasdiagMailer::EmailsController, type: :request do
#   describe 'GET #send_all' do
#     let(:current_time) { Time.now }
#     let!(:inst) { create(:institution, id: 1) }
#     let!(:contractor) { create(:contractor, institution_id: inst.id) }
#     let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

#     before do
#       allow(Time).to receive(:now).and_return(current_time)
#     end

#     context 'when the request is made within 30 seconds' do
#       before do
#         Rails.configuration.last_use_of_send_all_mail = current_time - 20.seconds
#       end

#       it 'returns status 429 with an error message' do      	
#         get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header
#         expect(response).to have_http_status(429)
#         expect(response.body).to include_json(error: "too many requests, the use of this endpoint is limited to 1 request per 30 seconds")
#       end

#       it 'not enqueues SendNotificationsJob and SendNotificationForPatients' do
#         expect(MasdiagMailer::SendNotificationsJob).not_to receive(:perform_later)
#         expect(MasdiagMailer::SendNotificationForPatients).not_to receive(:perform_later)

#         get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header
#       end
#     end

#     context 'when the request is made after 30 seconds' do
#       before do
#         Rails.configuration.last_use_of_send_all_mail = current_time - 31.seconds
#       end

#       it 'enqueues SendNotificationsJob and SendNotificationForPatients' do
#         expect(MasdiagMailer::SendNotificationsJob).to receive(:perform_later)
#         expect(MasdiagMailer::SendNotificationForPatients).to receive(:perform_later)

#         get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header
#       end

#       it 'updates last_use_of_send_all_mail to the current time' do
#         get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header
#         expect(Rails.configuration.last_use_of_send_all_mail).to eq(current_time)
#       end

#       it 'returns status 200 with "OK" message' do
#         get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header
#         expect(response).to have_http_status(200)
#         expect(response.body).to eq("OK")
#       end
#     end
#   end
# end