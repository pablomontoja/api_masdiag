require "rails_helper"

RSpec.describe Notifications::RegistrationReminderFinalJob, type: :job do
  let(:sample_a) { create(:sample, Code: "TXA1") }
  let(:sample_b) { create(:sample, Code: "TXB1") }

  it "dispatches :registration_reminder_final for each finder result" do
    allow(Notifications::RegistrationRemindersFinder).to receive(:call).and_return([sample_a, sample_b])

    expect(Notifications::EventDispatcher).to receive(:call).with(event: :registration_reminder_final, sample: sample_a)
    expect(Notifications::EventDispatcher).to receive(:call).with(event: :registration_reminder_final, sample: sample_b)

    described_class.perform_now
  end

  it "does nothing when the finder returns no samples" do
    allow(Notifications::RegistrationRemindersFinder).to receive(:call).and_return([])
    expect(Notifications::EventDispatcher).not_to receive(:call)
    described_class.perform_now
  end

  it "is configured to retry on StandardError" do
    expect(described_class.rescue_handlers.map(&:first)).to include("StandardError")
  end
end
