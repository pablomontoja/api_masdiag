require 'rails_helper'
require 'rspec/json_expectations'

RSpec.describe MasdiagMailer::EmailsController, type: :request do

  describe 'GET #send_all' do
    let(:current_time) { Time.now }
    let!(:inst) { create(:institution, id: 1) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

    before do
      allow(Time).to receive(:now).and_return(current_time)
    end

    context 'when the request is made within 60 seconds' do
      before do
        Rails.configuration.last_use_of_send_all_mail = current_time - 40.seconds
      end

      it 'returns status 429 with an error message' do      	
        get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
        expect(response).to have_http_status(429)
        expect(response.body).to include_json(error: "too many requests, the use of this endpoint is limited to 1 request per 60 seconds")
      end

      it 'not enqueues ContractorResultsNotifierJob and PatientResultsNotifierJob' do
        expect(MasdiagMailer::ContractorResultsNotifierJob).not_to receive(:perform_later)
        expect(MasdiagMailer::PatientResultsNotifierJob).not_to receive(:perform_later)

        get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
      end
    end

    context 'when the request is made after 60 seconds' do
      before do
        Rails.configuration.last_use_of_send_all_mail = current_time - 61.seconds
      end

      it 'enqueues ContractorResultsNotifierJob and PatientResultsNotifierJob' do
        expect(MasdiagMailer::ContractorResultsNotifierJob).to receive(:perform_later)
        expect(MasdiagMailer::PatientResultsNotifierJob).to receive(:perform_later)

        get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
      end

      it 'updates last_use_of_send_all_mail to the current time' do
        get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
        expect(Rails.configuration.last_use_of_send_all_mail).to eq(current_time)
      end

      it 'returns status 200 with "OK" message' do
        get '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
        expect(response).to have_http_status(200)
        expect(response.body).to eq("OK")
      end
    end
  end

  describe "POST #send_cancellation_notifications" do
    let(:sample_ids) { [1, 2, 3] }
    let(:endpoint) { "/masdiag_mailer/send_cancellation_notifications" }
    let!(:inst) { create(:institution, id: 1) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
    
    context "when the job is successfully enqueued" do
      it "returns status 200 with 'OK' response" do
        expect(MasdiagMailer::SendCancellationNotificationsJob).to receive(:perform_later).with(sample_ids)
        
        post endpoint, params: { sample_ids: sample_ids }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(200)
        expect(response.body).to eq("OK")
      end
    end
    
    context "when an error occurs" do
      before do
        allow(MasdiagMailer::SendCancellationNotificationsJob).to receive(:perform_later).and_raise(StandardError.new("Test error"))
      end
      
      it "returns status 500 with error message" do
        post endpoint, params: { sample_ids: sample_ids }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)["error"]).to eq("Test error")
      end
    end
  end

  describe "POST #send_acceptance_notifications" do
    let(:sample_ids) { [1, 2, 3] }
    let(:endpoint) { "/masdiag_mailer/send_acceptance_notifications" }
    let!(:inst) { create(:institution, id: 1) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
    
    context "when the job is successfully enqueued" do
      it "returns status 200 with 'OK' response" do
        expect(MasdiagMailer::SendAcceptanceNotificationsJob).to receive(:perform_later).with(sample_ids)
        
        post endpoint, params: { sample_ids: sample_ids }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(200)
        expect(response.body).to eq("OK")
      end
    end
    
    context "when an error occurs" do
      before do
        allow(MasdiagMailer::SendAcceptanceNotificationsJob).to receive(:perform_later).and_raise(StandardError.new("Test error"))
      end
      
      it "returns status 500 with error message" do
        post endpoint, params: { sample_ids: sample_ids }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)["error"]).to eq("Test error")
      end
    end
  end

  describe 'POST #send_error_notifications' do
    let(:params) { { error_message: 'Something went wrong', application: 'TestApp' } }
    let!(:inst) { create(:institution, id: 1) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

    context 'when email delivery is successful' do
      before do
        allow(MasdiagMailer::SendErrorNotificationsMailer).to receive(:send_mail).and_return(
          double(deliver_later: true)
        )
      end

      it 'returns a 200 OK status with "OK" text' do
        post '/masdiag_mailer/send_error_notifications', params: params.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(200)
        expect(response.body).to eq('OK')
      end

      it 'calls the mailer with the correct parameters' do
        expect(MasdiagMailer::SendErrorNotificationsMailer).to receive(:send_mail).with(
          hash_including(params)
        ).and_return(double(deliver_later: true))
        
        post '/masdiag_mailer/send_error_notifications', params: params.to_json, headers: http_auth_header_with_json_content_type
      end
    end

    context 'when email delivery fails' do
      before do
        allow(MasdiagMailer::SendErrorNotificationsMailer).to receive(:send_mail).and_raise(
          StandardError.new('Email delivery failed')
        )
      end

      it 'returns a 500 status with error details' do
        post '/masdiag_mailer/send_error_notifications', params: params.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)['error']).to eq('Email delivery failed')
      end
    end
  end




end