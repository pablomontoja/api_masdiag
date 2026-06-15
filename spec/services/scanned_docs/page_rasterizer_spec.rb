require 'rails_helper'

RSpec.describe ScannedDocs::PageRasterizer do
  let(:png_data) { ("\x89PNG\r\n\x1a\n" + "fake png bytes").b }

  describe '#to_png_bytes' do
    let(:tmp_pdf) do
      f = Tempfile.new(['page', '.pdf'])
      f.write("%PDF-1.4")
      f.rewind
      f
    end

    after { tmp_pdf.close }

    it 'returns PNG bytes on success' do
      attachment = double('attachment')
      allow(attachment).to receive(:open).and_yield(tmp_pdf)
      allow(Open3).to receive(:capture3).and_return(
        ['', '', instance_double(Process::Status, success?: true)]
      )

      dir = Dir.mktmpdir
      allow(Dir).to receive(:mktmpdir).and_return(dir)
      File.binwrite(File.join(dir, "page.png"), png_data)

      result = described_class.new(attachment).to_png_bytes
      expect(result).to eq(png_data)
    end

    it 'raises on non-zero pdftoppm exit' do
      attachment = double('attachment')
      allow(attachment).to receive(:open).and_yield(tmp_pdf)
      allow(Open3).to receive(:capture3).and_return(
        ['', 'error output', instance_double(Process::Status, success?: false)]
      )

      expect {
        described_class.new(attachment).to_png_bytes
      }.to raise_error(RuntimeError, /rasterize failed/)
    end
  end
end
