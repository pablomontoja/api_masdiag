require "rails_helper"

RSpec.describe Notifications::RegistrationReminderJob, type: :job do
  let!(:sample) { create(:sample, Code: "TXCODE") }

  it "resolves the sample by Id and dispatches :registration_reminder" do
    expect(Notifications::EventDispatcher).to receive(:call).with(event: :registration_reminder, sample: sample)
    described_class.perform_now(sample.Id)
  end

  it "resolves the sample by Code and dispatches :registration_reminder" do
    expect(Notifications::EventDispatcher).to receive(:call).with(event: :registration_reminder, sample: sample)
    described_class.perform_now("TXCODE")
  end

  it "does nothing when neither Id nor Code matches" do
    expect(Notifications::EventDispatcher).not_to receive(:call)
    described_class.perform_now("NOPE99")
  end

  it "is configured to retry on StandardError" do
    expect(described_class.rescue_handlers.map(&:first)).to include("StandardError")
  end
end
