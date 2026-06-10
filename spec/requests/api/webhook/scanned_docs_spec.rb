require 'rails_helper'

RSpec.describe 'Api::Webhook::ScannedDocs', type: :request do
  let(:valid_token) { 'test-secret-token' }
  let(:bearer_headers) { { 'Authorization' => "Bearer #{valid_token}" } }

  let(:minimal_pdf) do
    Rack::Test::UploadedFile.new(
      StringIO.new("%PDF-1.4 minimal valid pdf content"),
      'application/pdf',
      original_filename: 'page-1.pdf'
    )
  end

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig)
      .with(:scan_webhook, :token)
      .and_return(valid_token)
    allow(ScannedDocs::OcrJob).to receive(:perform_later)
  end

  describe 'POST /webhook/scanned_docs' do
    let(:checksum) { Digest::SHA256.hexdigest("%PDF-1.4 minimal valid pdf content") }
    let(:valid_params) do
      {
        file: minimal_pdf,
        page_checksum: checksum,
        source_filename: 'original.pdf'
      }
    end

    context 'with valid bearer token and new page' do
      it 'returns 202 with status stored' do
        post '/webhook/scanned_docs', params: valid_params, headers: bearer_headers
        expect(response).to have_http_status(:accepted)
        expect(json['status']).to eq('stored')
        expect(json['id']).to be_present
      end

      it 'creates a ScannedDoc record' do
        expect {
          post '/webhook/scanned_docs', params: valid_params, headers: bearer_headers
        }.to change(ScannedDoc, :count).by(1)
      end

      it 'attaches page_pdf to the record' do
        post '/webhook/scanned_docs', params: valid_params, headers: bearer_headers
        doc = ScannedDoc.last
        expect(doc.page_pdf).to be_attached
      end

      it 'sets status to ready' do
        post '/webhook/scanned_docs', params: valid_params, headers: bearer_headers
        expect(ScannedDoc.last.status).to eq('ready')
      end

      # it 'enqueues OcrJob' do
      #   post '/webhook/scanned_docs', params: valid_params, headers: bearer_headers
      #   expect(ScannedDocs::OcrJob).to have_received(:perform_later).with(ScannedDoc.last.id)
      # end
    end

    context 'with duplicate checksum' do
      before { create(:scanned_doc, :with_page_pdf, page_checksum: checksum) }

      it 'returns 202 with status duplicate' do
        post '/webhook/scanned_docs', params: valid_params, headers: bearer_headers
        expect(response).to have_http_status(:accepted)
        expect(json['status']).to eq('duplicate')
      end

      it 'does not create a new record' do
        expect {
          post '/webhook/scanned_docs', params: valid_params, headers: bearer_headers
        }.not_to change(ScannedDoc, :count)
      end

      it 'does not enqueue OcrJob' do
        post '/webhook/scanned_docs', params: valid_params, headers: bearer_headers
        expect(ScannedDocs::OcrJob).not_to have_received(:perform_later)
      end
    end

    context 'with wrong bearer token' do
      it 'returns 401' do
        post '/webhook/scanned_docs',
          params: valid_params,
          headers: { 'Authorization' => 'Bearer wrong-token' }
        expect(response).to have_http_status(:unauthorized)
        expect(json['error']).to eq('unauthorized')
      end
    end

    context 'with missing authorization header' do
      it 'returns 401' do
        post '/webhook/scanned_docs', params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with missing page_checksum' do
      it 'returns 422' do
        post '/webhook/scanned_docs',
          params: valid_params.except(:page_checksum),
          headers: bearer_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with non-PDF file' do
      let(:non_pdf) do
        Rack::Test::UploadedFile.new(
          StringIO.new("not a pdf file"),
          'application/pdf',
          original_filename: 'fake.pdf'
        )
      end

      it 'returns 422' do
        post '/webhook/scanned_docs',
          params: { file: non_pdf, page_checksum: 'abc123', source_filename: 'fake.pdf' },
          headers: bearer_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).to eq('not a PDF')
      end
    end

    context 'with unknown sample_id' do
      it 'stores the record with sample_id NULL' do
        post '/webhook/scanned_docs',
          params: valid_params.merge(sample_id: 999_999),
          headers: bearer_headers
        expect(response).to have_http_status(:accepted)
        expect(json['status']).to eq('stored')
        expect(ScannedDoc.last.sample_id).to be_nil
      end
    end
  end
end
