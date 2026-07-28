require "rails_helper"

RSpec.describe Contractor, type: :model do
  describe "notification opt-out flags" do
    subject(:contractor) { create(:contractor) }

    it "defaults every per-event notification flag to true (opt-out model)" do
      expect(contractor.allow_sample_acceptance_notifications).to be(true)
      expect(contractor.allow_sample_rejection_notifications).to be(true)
      expect(contractor.allow_result_notifications).to be(true)
      expect(contractor.allow_sample_registration_notifications).to be(true)
    end

    it "persists a disabled flag" do
      contractor.update!(allow_result_notifications: false)
      expect(contractor.reload.allow_result_notifications).to be(false)
    end
  end
end
