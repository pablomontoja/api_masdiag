require 'rails_helper'

RSpec.describe Hl7Import, type: :model do
  describe "enum status" do
    it "defines all status values" do
      expect(described_class.statuses).to include(
        "pending"               => 0,
        "processing"            => 1,
        "completed"             => 2,
        "failed"                => 3,
        "awaiting_registration" => 4,
        "registration_error"    => 5,
        "retry_scheduled"       => 6
      )
    end
  end

  describe ".ready_for_retry" do
    it "returns failed imports with retry_count < 3" do
      eligible   = create(:hl7_import, :failed, retry_count: 0)
      also_eligible = create(:hl7_import, :failed, retry_count: 2)
      exhausted  = create(:hl7_import, :failed, retry_count: 3)
      not_failed = create(:hl7_import, status: :completed)

      result = described_class.ready_for_retry
      expect(result).to include(eligible, also_eligible)
      expect(result).not_to include(exhausted, not_failed)
    end
  end

  describe "#mark_completed!" do
    it "sets status to completed, processed_at, and processing_stats" do
      import = create(:hl7_import, status: :processing)
      stats  = { analytes_created: 5, analytes_skipped: 1 }

      import.mark_completed!(stats)
      import.reload

      expect(import.status).to eq("completed")
      expect(import.processed_at).to be_present
      expect(import.processing_stats).to be_present
    end
  end

  describe "#mark_failed!" do
    it "sets status to failed with error message" do
      import = create(:hl7_import, status: :processing)

      import.mark_failed!("Missing MSH segment")
      import.reload

      expect(import.status).to eq("failed")
      expect(import.error_message).to eq("Missing MSH segment")
    end
  end

  describe "#mark_awaiting_registration!" do
    it "sets status to awaiting_registration with reason" do
      import = create(:hl7_import, status: :pending)

      import.mark_awaiting_registration!("Kit not found")
      import.reload

      expect(import.status).to eq("awaiting_registration")
      expect(import.error_message).to eq("Kit not found")
    end
  end

  describe "#mark_registration_error!" do
    it "sets status to registration_error with reason" do
      import = create(:hl7_import, status: :pending)

      import.mark_registration_error!("Measurement already has HL7 import")
      import.reload

      expect(import.status).to eq("registration_error")
      expect(import.error_message).to eq("Measurement already has HL7 import")
    end
  end

  describe "associations" do
    it "belongs_to measurement optionally" do
      import = build(:hl7_import, measurement: nil)
      expect(import).to be_valid
    end

    it "has_one_attached hl7_file" do
      expect(described_class.new).to respond_to(:hl7_file)
    end
  end
end
