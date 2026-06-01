require 'rails_helper'

RSpec.describe Hl7LinkPendingJob, type: :job do
  describe "#perform" do
    it "delegates to Hl7::PendingImportLinker#link_pending_imports" do
      linker = instance_double(Hl7::PendingImportLinker,
                               link_pending_imports: { linked: 0, waiting: 0, errors: [] })
      allow(Hl7::PendingImportLinker).to receive(:new).and_return(linker)

      described_class.new.perform

      expect(linker).to have_received(:link_pending_imports)
    end
  end
end
