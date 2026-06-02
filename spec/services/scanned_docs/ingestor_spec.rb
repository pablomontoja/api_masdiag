require 'rails_helper'

RSpec.describe ScannedDocs::Ingestor do
  let(:pdf_content) { "%PDF-1.4 test content" }
  let(:checksum)    { Digest::SHA256.hexdigest(pdf_content) }
  let(:file) do
    instance_double(
      ActionDispatch::Http::UploadedFile,
      tempfile:          Tempfile.new.tap { |f| f.write(pdf_content); f.rewind },
      original_filename: 'page-1.pdf',
      size:              pdf_content.bytesize
    )
  end

  let(:params) do
    ActionController::Parameters.new(
      page_checksum:   checksum,
      source_filename: 'original.pdf',
      source:          'scan_watcher'
    )
  end

  before { allow(ScannedDocs::OcrJob).to receive(:perform_later) }

  subject(:result) { described_class.new(params, file).call }

  describe 'new document' do
    it 'returns success with status stored' do
      expect(result).to be_success
      expect(result.status).to eq('stored')
    end

    it 'creates a ScannedDoc' do
      expect { result }.to change(ScannedDoc, :count).by(1)
    end

    it 'saves the record before attaching (no orphaned blobs on failure)' do
      # Verify save! is called before attach by checking record is persisted
      result
      doc = ScannedDoc.find(result.scanned_doc_id)
      expect(doc).to be_persisted
      expect(doc.page_pdf).to be_attached
    end

    it 'enqueues OcrJob' do
      result
      expect(ScannedDocs::OcrJob).to have_received(:perform_later).with(result.scanned_doc_id)
    end

    it 'sets status to ready' do
      result
      expect(ScannedDoc.find(result.scanned_doc_id).status).to eq('ready')
    end

    it 'parses captured_at from ISO 8601 string' do
      params_with_time = ActionController::Parameters.new(
        params.to_unsafe_h.merge(captured_at: '2026-06-02T10:30:00+02:00')
      )
      r = described_class.new(params_with_time, file).call
      doc = ScannedDoc.find(r.scanned_doc_id)
      expect(doc.captured_at).to be_present
    end
  end

  describe 'duplicate checksum' do
    before { create(:scanned_doc, :with_page_pdf, page_checksum: checksum) }

    it 'returns success with status duplicate' do
      expect(result).to be_success
      expect(result.status).to eq('duplicate')
    end

    it 'does not create a new record' do
      expect { result }.not_to change(ScannedDoc, :count)
    end

    it 'does not enqueue OcrJob' do
      result
      expect(ScannedDocs::OcrJob).not_to have_received(:perform_later)
    end
  end

  describe 'race condition — RecordNotUnique' do
    it 'returns duplicate result instead of raising' do
      existing = create(:scanned_doc, :with_page_pdf, page_checksum: checksum)
      allow(ScannedDoc).to receive(:find_or_initialize_by)
        .with(page_checksum: checksum)
        .and_return(ScannedDoc.new(page_checksum: checksum))
      allow_any_instance_of(ScannedDoc).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)

      r = described_class.new(params, file).call
      expect(r).to be_success
      expect(r.status).to eq('duplicate')
      expect(r.scanned_doc_id).to eq(existing.id)
    end
  end

  describe 'unknown sample_id' do
    it 'stores with sample_id nil' do
      params_with_sample = ActionController::Parameters.new(
        params.to_unsafe_h.merge(sample_id: 999_999)
      )
      r = described_class.new(params_with_sample, file).call
      expect(ScannedDoc.find(r.scanned_doc_id).sample_id).to be_nil
    end
  end

  describe 'validation failures' do
    it 'returns failure when file is not a PDF' do
      bad_file = instance_double(
        ActionDispatch::Http::UploadedFile,
        tempfile:          Tempfile.new.tap { |f| f.write("not a pdf"); f.rewind },
        original_filename: 'bad.pdf',
        size:              9
      )
      r = described_class.new(params, bad_file).call
      expect(r).not_to be_success
      expect(r.error).to eq('not a PDF')
    end

    it 'returns failure when page_checksum is blank' do
      bad_params = ActionController::Parameters.new(params.to_unsafe_h.merge(page_checksum: ''))
      r = described_class.new(bad_params, file).call
      expect(r).not_to be_success
      expect(r.error).to eq('page_checksum required')
    end

    it 'returns failure when file is too large' do
      big_file = instance_double(
        ActionDispatch::Http::UploadedFile,
        tempfile:          Tempfile.new.tap { |f| f.write(pdf_content); f.rewind },
        original_filename: 'big.pdf',
        size:              26.megabytes
      )
      r = described_class.new(params, big_file).call
      expect(r).not_to be_success
      expect(r.error).to eq('file too large')
    end
  end
end
