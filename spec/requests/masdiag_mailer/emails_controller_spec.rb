require 'rails_helper'
require 'rspec/json_expectations'

RSpec.describe MasdiagMailer::EmailsController, type: :request do

  describe 'POST #send_all' do
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
        post '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
        expect(response).to have_http_status(429)
        expect(response.body).to include_json(error: "too many requests, the use of this endpoint is limited to 1 request per 60 seconds")
      end

      it 'not enqueues ContractorResultsNotifierJob, PatientResultsNotifierJob, and ResultAvailableSweepJob' do
        expect(MasdiagMailer::ContractorResultsNotifierJob).not_to receive(:perform_later)
        expect(MasdiagMailer::PatientResultsNotifierJob).not_to receive(:perform_later)
        expect(Notifications::ResultAvailableSweepJob).not_to receive(:perform_later)

        post '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
      end
    end

    context 'when the request is made after 60 seconds' do
      before do
        Rails.configuration.last_use_of_send_all_mail = current_time - 61.seconds
      end

      it 'enqueues ContractorResultsNotifierJob, PatientResultsNotifierJob, and ResultAvailableSweepJob' do
        expect(MasdiagMailer::ContractorResultsNotifierJob).to receive(:perform_later)
        expect(MasdiagMailer::PatientResultsNotifierJob).to receive(:perform_later)
        expect(Notifications::ResultAvailableSweepJob).to receive(:perform_later)

        post '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
      end

      it 'updates last_use_of_send_all_mail to the current time' do
        post '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
        expect(Rails.configuration.last_use_of_send_all_mail).to eq(current_time)
      end

      it 'returns status 200 with "OK" message' do
        post '/masdiag_mailer/send_all_mails', params: {}, headers: http_auth_header_with_json_content_type
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


  describe "POST #send_notification_after_delayed_reg" do
    let(:sample_id) { 1000 }
    let(:endpoint) { "/masdiag_mailer/send_notification_after_delayed_reg" }
    let!(:inst) { create(:institution, id: 1) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
    
    context "when the job is successfully enqueued" do
      it "returns status 200 with 'OK' response" do
        expect(MasdiagMailer::SendNotificationAfterDelayedRegJob).to receive(:perform_later).with(sample_id)
        
        post endpoint, params: { sample_id: sample_id }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(200)
        expect(response.body).to eq("OK")
      end
    end
    
    context "when an error occurs" do
      before do
        allow(MasdiagMailer::SendNotificationAfterDelayedRegJob).to receive(:perform_later).and_raise(StandardError.new("Test error"))
      end
      
      it "returns status 500 with error message" do
        post endpoint, params: { sample_id: sample_id }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)["error"]).to eq("Test error")
      end
    end
  end


  describe 'POST #after_sample_registration' do
    let(:sample_id) { 12345 }
    let(:project_id) { 25 }
    let!(:inst) { create(:institution, id: 1) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }

    context 'when sample is associated with project 25' do
      before do
        allow(Measurement).to receive(:where).with(SampleId: sample_id, ProjectId: project_id).and_return([double('Measurement')])
        allow(MasdiagMailer::ThreeMethylDopaMailer).to receive(:after_sample_registration).with(sample_id).and_return(double('Mailer', deliver_later: true))
      end

      it 'sends email via ThreeMethylDopaMailer' do
        expect(MasdiagMailer::ThreeMethylDopaMailer).to receive(:after_sample_registration).with(sample_id).and_return(double('Mailer', deliver_later: true))
        
        post '/masdiag_mailer/after_sample_registration', params: { sample_id: sample_id }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(200)
        expect(response.body).to eq('OK')
      end
    end

    context 'when sample is not associated with project 25' do
      before do
        allow(Measurement).to receive(:where).with(SampleId: sample_id, ProjectId: project_id).and_return([])
        allow(MasdiagMailer::IndMailer).to receive(:after_sample_registration).with(sample_id).and_return(double('Mailer', deliver_later: true))
      end

      it 'sends email via IndMailer' do
        expect(MasdiagMailer::IndMailer).to receive(:after_sample_registration).with(sample_id).and_return(double('Mailer', deliver_later: true))
        
        post '/masdiag_mailer/after_sample_registration', params: { sample_id: sample_id }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(200)
        expect(response.body).to eq('OK')
      end
    end

    context 'when an error occurs' do
      before do
        allow(Measurement).to receive(:where).with(SampleId: sample_id, ProjectId: project_id).and_raise(StandardError.new('Something went wrong'))
      end

      it 'returns 500 status with error message' do
        post '/masdiag_mailer/after_sample_registration', params: { sample_id: sample_id }.to_json, headers: http_auth_header_with_json_content_type

        expect(response).to have_http_status(500)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Something went wrong' })
      end
    end

    context 'when the contractor disabled sample registration notifications' do
      let!(:sample) { create(:sample, patient: create(:patient, contractor: contractor)) }
      let(:sample_id) { sample.Id }

      before do
        contractor.update_column(:allow_sample_registration_notifications, false)
      end

      it 'does not send any mail and returns 200 OK' do
        expect(MasdiagMailer::IndMailer).not_to receive(:after_sample_registration)
        expect(MasdiagMailer::ThreeMethylDopaMailer).not_to receive(:after_sample_registration)

        post '/masdiag_mailer/after_sample_registration', params: { sample_id: sample_id }.to_json, headers: http_auth_header_with_json_content_type

        expect(response).to have_http_status(200)
        expect(response.body).to eq('OK')
      end
    end
  end


  describe "POST shipping_after_new_order" do
    let(:shop_order_id) { 123 }
    let!(:inst) { create(:institution, id: 1) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
    
    context "when successful" do
      before do
        allow(MasdiagMailer::IndMailer).to receive(:shipping_after_new_order).with(shop_order_id).and_return(double(deliver_later: true))
      end
      
      it "returns a 200 OK status" do
        post "/masdiag_mailer/shipping_after_new_order", params: { shop_order_id: shop_order_id }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(200)
        expect(response.body).to eq("OK")
      end
      
      it "calls the MasdiagMailer::IndMailer with the shop_order_id" do
        expect(MasdiagMailer::IndMailer).to receive(:shipping_after_new_order).with(shop_order_id)
        
        post "/masdiag_mailer/shipping_after_new_order", params: { shop_order_id: shop_order_id }.to_json, headers: http_auth_header_with_json_content_type
      end
    end
    
    context "when an error occurs" do
      let(:error_message) { "Something went wrong" }
      
      before do
        allow(MasdiagMailer::IndMailer).to receive(:shipping_after_new_order).with(shop_order_id).and_raise(StandardError.new(error_message))
      end
      
      it "returns a 500 status with the error message" do
        post "/masdiag_mailer/shipping_after_new_order", params: { shop_order_id: shop_order_id }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(500)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["error"]).to eq(error_message)
      end
    end
  end

  describe "POST after_new_order_save" do
    let(:shop_order_id) { 123 }
    let!(:inst) { create(:institution, id: 1) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
    
    context "when successful" do
      before do
        allow(MasdiagMailer::IndMailer).to receive(:after_new_order_save).with(shop_order_id).and_return(double(deliver_later: true))
      end
      
      it "returns a 200 OK status" do
        post "/masdiag_mailer/after_new_order_save", params: { shop_order_id: shop_order_id }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(200)
        expect(response.body).to eq("OK")
      end
      
      it "calls the MasdiagMailer::IndMailer with the shop_order_id" do
        expect(MasdiagMailer::IndMailer).to receive(:after_new_order_save).with(shop_order_id)
        
        post "/masdiag_mailer/after_new_order_save", params: { shop_order_id: shop_order_id }.to_json, headers: http_auth_header_with_json_content_type
      end
    end
    
    context "when an error occurs" do
      let(:error_message) { "Something went wrong" }
      
      before do
        allow(MasdiagMailer::IndMailer).to receive(:after_new_order_save).with(shop_order_id).and_raise(StandardError.new(error_message))
      end
      
      it "returns a 500 status with the error message" do
        post "/masdiag_mailer/after_new_order_save", params: { shop_order_id: shop_order_id }.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(500)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["error"]).to eq(error_message)
      end
    end
  end


  describe 'POST #masdiag_website_contact_form' do
    let(:valid_params) do
      {
        name: 'John Doe',
        email: 'john@example.com',
        message: 'Hello, this is a test message.'
      }
    end
    let!(:inst) { create(:institution, id: 1) }
    let!(:contractor) { create(:contractor, institution_id: inst.id) }
    let!(:api_account) { create(:api_account, contractor_id: contractor.Id) }
    
    context 'with valid parameters' do
      it 'returns a success response' do
        allow(MasdiagMailer::MasdiagPlContactFormMailer).to receive(:send_mail).and_return(double(deliver_later: true))
        
        post '/masdiag_mailer/masdiag_website_contact_form', params: valid_params.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('OK')
      end

      it 'calls the mailer with correct parameters' do
        expect(MasdiagMailer::MasdiagPlContactFormMailer).to receive(:send_mail)
          .with({ name: 'John Doe', email: 'john@example.com', message: 'Hello, this is a test message.' })
          .and_return(double(deliver_later: true))
        
        post '/masdiag_mailer/masdiag_website_contact_form', params: valid_params.to_json, headers: http_auth_header_with_json_content_type
      end
    end

    context 'when an error occurs' do
      it 'returns a 500 status with error message' do
        allow(MasdiagMailer::MasdiagPlContactFormMailer).to receive(:send_mail)
          .and_raise(StandardError.new('Something went wrong'))
        
        post '/masdiag_mailer/masdiag_website_contact_form', params: valid_params.to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Something went wrong')
      end
    end

    context 'with missing parameters' do
      it 'fails when email is missing' do
        allow(MasdiagMailer::MasdiagPlContactFormMailer).to receive(:send_mail)
          .and_raise(StandardError.new('Email is required'))
        
        post '/masdiag_mailer/masdiag_website_contact_form', params: valid_params.except(:email).to_json, headers: http_auth_header_with_json_content_type
        
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Email is required')
      end
    end
  end



end