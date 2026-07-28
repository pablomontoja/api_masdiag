require "rails_helper"

RSpec.describe Notifications::ResultAvailableJob, type: :job do
  let(:sample) { create(:sample) }

  it "delegates to EventDispatcher with event :result_available" do
    expect(Notifications::EventDispatcher).to receive(:call).with(event: :result_available, sample: sample)
    described_class.perform_now(sample.Id)
  end

  it "does nothing for a missing sample" do
    expect(Notifications::EventDispatcher).not_to receive(:call)
    described_class.perform_now(999_999)
  end

  it "is configured to retry on StandardError" do
    expect(described_class.rescue_handlers.map(&:first)).to include("StandardError")
  end
end
