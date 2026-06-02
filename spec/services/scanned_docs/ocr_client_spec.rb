require 'rails_helper'

RSpec.describe ScannedDocs::OcrClient do
  let(:png_bytes)    { "fake png data" }
  let(:markdown_text) { "# Lab Result\n\nSome transcription text." }
  let(:ocr_response) do
    {
      choices: [{ message: { content: markdown_text } }]
    }.to_json
  end

  describe '#transcribe' do
    it 'returns markdown string from successful response' do
      http_response = instance_double(Net::HTTPSuccess, is_a?: true, body: ocr_response)
      allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      allow(Net::HTTP).to receive(:start).and_yield(
        instance_double(Net::HTTP, request: http_response)
      ).and_return(http_response)

      result = described_class.new.transcribe(png_bytes)
      expect(result).to eq(markdown_text)
    end

    it 'raises on non-success HTTP response' do
      http_response = instance_double(Net::HTTPInternalServerError,
        is_a?: false, code: '500')
      allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)

      allow(Net::HTTP).to receive(:start).and_yield(
        instance_double(Net::HTTP, request: http_response)
      ).and_return(http_response)

      expect {
        described_class.new.transcribe(png_bytes)
      }.to raise_error(RuntimeError, /OCR server error 500/)
    end
  end
end
