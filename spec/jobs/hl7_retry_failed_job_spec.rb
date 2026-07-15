require 'rails_helper'

RSpec.describe Hl7RetryFailedJob, type: :job do
  describe "#perform" do
    it "enqueues MeasurementImportJob for each eligible failed import" do
      imp1 = create(:hl7_import, :failed)
      imp2 = create(:hl7_import, :failed)
      imp1.update_column(:retry_count, 1)
      imp2.update_column(:retry_count, 2)

      expect(Hl7::MeasurementImportJob).to receive(:perform_later).with(imp1.id)
      expect(Hl7::MeasurementImportJob).to receive(:perform_later).with(imp2.id)

      described_class.new.perform

      expect(imp1.reload.status).to eq("retry_scheduled")
      expect(imp1.reload.retry_count).to eq(2)
      expect(imp2.reload.retry_count).to eq(3)
    end

    it "skips exhausted imports (retry_count >= 3)" do
      exhausted = create(:hl7_import, :failed)
      exhausted.update_column(:retry_count, 3)

      expect(Hl7::MeasurementImportJob).not_to receive(:perform_later)

      described_class.new.perform
    end
  end
end
