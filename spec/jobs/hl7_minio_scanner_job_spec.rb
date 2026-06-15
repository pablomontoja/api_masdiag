require 'rails_helper'

RSpec.describe Hl7MinioScannerJob, type: :job do
  describe "#perform" do
    it "delegates to Hl7::MinioScanner#scan_and_import" do
      scanner = instance_double(Hl7::MinioScanner, scan_and_import: { new_files: 0, errors: [] })
      allow(Hl7::MinioScanner).to receive(:new).and_return(scanner)

      described_class.new.perform

      expect(scanner).to have_received(:scan_and_import)
    end

    it "logs a warning when errors are present" do
      scanner = instance_double(Hl7::MinioScanner,
                                scan_and_import: { new_files: 0, errors: ["file.hl7: parse error"] })
      allow(Hl7::MinioScanner).to receive(:new).and_return(scanner)

      expect(Rails.logger).to receive(:warn).with(match(/Errors/))
      described_class.new.perform
    end
  end
end
