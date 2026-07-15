require 'rails_helper'

RSpec.describe ScannedDoc, type: :model do
  describe 'validations' do
    it 'requires source_filename' do
      doc = build(:scanned_doc, source_filename: nil)
      expect(doc).not_to be_valid
      expect(doc.errors[:source_filename]).to be_present
    end

    it 'requires page_checksum' do
      doc = build(:scanned_doc, page_checksum: nil)
      expect(doc).not_to be_valid
    end

    it 'enforces uniqueness of page_checksum' do
      create(:scanned_doc, page_checksum: 'abc123')
      dup = build(:scanned_doc, page_checksum: 'abc123')
      expect(dup).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to sample optionally' do
      doc = build(:scanned_doc, sample: nil)
      expect(doc).to be_valid
    end

    it 'has page_pdf attachment' do
      expect(described_class.new).to respond_to(:page_pdf)
    end

    it 'has markdown attachment' do
      expect(described_class.new).to respond_to(:markdown)
    end
  end

  describe 'enum status' do
    it 'defaults to ready' do
      doc = described_class.new
      expect(doc.status).to eq('ready')
    end

    it 'supports all status values' do
      expect(described_class.statuses.keys).to match_array(%w[ready ocr_pending transcribed failed])
    end

    it 'maps correct integer values' do
      expect(described_class.statuses['ready']).to eq(0)
      expect(described_class.statuses['ocr_pending']).to eq(1)
      expect(described_class.statuses['transcribed']).to eq(2)
      expect(described_class.statuses['failed']).to eq(9)
    end
  end

  describe 'scopes' do
    it 'awaiting_ocr returns only ready records' do
      ready    = create(:scanned_doc)
      _pending = create(:scanned_doc, :ocr_pending)
      _done    = create(:scanned_doc, :transcribed)

      expect(described_class.awaiting_ocr).to contain_exactly(ready)
    end
  end

  describe '#transcription' do
    it 'returns nil when markdown not attached' do
      doc = build(:scanned_doc)
      expect(doc.transcription).to be_nil
    end

    it 'returns content when markdown attached' do
      doc = create(:scanned_doc, :transcribed)
      expect(doc.transcription).to eq("# OCR result\n")
    end
  end
end
