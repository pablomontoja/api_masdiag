require 'rails_helper'

RSpec.describe ScannedDocs::OcrJob, type: :job do
  let(:doc) { create(:scanned_doc, :with_page_pdf) }
  let(:png_bytes)    { "fake png bytes" }
  let(:markdown_text) { "# OCR output\n" }

  before do
    allow(ScannedDocs::PageRasterizer).to receive(:new).and_return(
      instance_double(ScannedDocs::PageRasterizer, to_png_bytes: png_bytes)
    )
    allow(ScannedDocs::OcrClient).to receive(:new).and_return(
      instance_double(ScannedDocs::OcrClient, transcribe: markdown_text)
    )
  end

  describe '#perform' do
    it 'transitions status ready → ocr_pending → transcribed' do
      described_class.perform_now(doc.id)
      doc.reload
      expect(doc.status).to eq('transcribed')
      expect(doc.ocr_started_at).to be_present
      expect(doc.transcribed_at).to be_present
    end

    it 'attaches markdown with transcription content' do
      described_class.perform_now(doc.id)
      doc.reload
      expect(doc.markdown).to be_attached
      expect(doc.markdown.download).to eq(markdown_text)
    end

    it 'exits early when doc is already transcribed' do
      doc.update!(status: :transcribed)
      described_class.perform_now(doc.id)
      expect(ScannedDocs::PageRasterizer).not_to have_received(:new)
    end

    it 'exits early when page_pdf is not attached' do
      doc_no_pdf = create(:scanned_doc)
      described_class.perform_now(doc_no_pdf.id)
      expect(ScannedDocs::PageRasterizer).not_to have_received(:new)
    end

    context 'when OcrClient raises' do
      let(:job) { described_class.new }

      before do
        ocr_client = double('OcrClient')
        allow(ocr_client).to receive(:transcribe).and_raise(RuntimeError, "Connection refused")
        allow(ScannedDocs::OcrClient).to receive(:new).and_return(ocr_client)
      end

      it 'sets status to failed and records error' do
        expect { job.perform(doc.id) }.to raise_error(RuntimeError)
        doc.reload
        expect(doc.status).to eq('failed')
        expect(doc.processing_error).to eq('Connection refused')
      end

      it 're-raises the error' do
        expect { job.perform(doc.id) }.to raise_error(RuntimeError, "Connection refused")
      end
    end
  end
end
