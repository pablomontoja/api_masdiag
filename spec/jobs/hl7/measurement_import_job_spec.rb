require 'rails_helper'

RSpec.describe Hl7::MeasurementImportJob, type: :job do
  describe "#perform" do
    it "finds the Hl7Import and delegates to Hl7::MeasurementImporter#import" do
      import    = create(:hl7_import)
      importer  = instance_double(Hl7::MeasurementImporter, import: true)
      allow(Hl7::MeasurementImporter).to receive(:new).with(import).and_return(importer)

      described_class.new.perform(import.id)

      expect(importer).to have_received(:import)
    end
  end
end
