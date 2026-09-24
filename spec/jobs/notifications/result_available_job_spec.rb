require "rails_helper"

RSpec.describe Notifications::ResultAvailableJob, type: :job do
  let(:sample) { create(:sample) }

  context "when the sample is eligible (qualifying measurement on/after CUTOFF_DATE)" do
    before do
      create(:measurement, sample: sample, project: create(:project_without_fixed_id),
                            AuthorizedAt: described_class::CUTOFF_DATE.in_time_zone + 1.day)
    end

    it "delegates to EventDispatcher with event :result_available" do
      expect(Notifications::EventDispatcher).to receive(:call).with(event: :result_available, sample: sample)
      described_class.perform_now(sample.Id)
    end
  end

  context "when the sample is ineligible (no qualifying measurement)" do
    it "does not dispatch and sends no email" do
      expect(Notifications::EventDispatcher).not_to receive(:call)
      expect {
        described_class.perform_now(sample.Id)
      }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  context "when the sample's only measurement is authorized before CUTOFF_DATE" do
    before do
      create(:measurement, sample: sample, project: create(:project_without_fixed_id),
                            AuthorizedAt: described_class::CUTOFF_DATE.in_time_zone - 1.day)
    end

    it "does not dispatch and sends no email" do
      expect(Notifications::EventDispatcher).not_to receive(:call)
      expect {
        described_class.perform_now(sample.Id)
      }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  it "does nothing for a missing sample" do
    expect(Notifications::EventDispatcher).not_to receive(:call)
    described_class.perform_now(999_999)
  end

  it "is configured to retry on StandardError" do
    expect(described_class.rescue_handlers.map(&:first)).to include("StandardError")
  end

  describe "idempotency of the full eligible+dispatch path (FR-008, US3)" do
    let(:toxo_institution) { create(:institution, name: "Toxo Inst") }

    before { stub_const("V1::Common::TOXO_INSTITUTION_IDS", [toxo_institution.id]) }

    def eligible_toxo_sample
      contractor = create(:contractor, institution: toxo_institution, email: "doc@example.com",
                                       are_notifications_enabled: true)
      patient = create(:patient, contractor: contractor, IsVirtual: false)
      sample = create(:sample, patient: patient)
      create(:measurement, sample: sample, project: create(:project_without_fixed_id),
                            AuthorizedAt: described_class::CUTOFF_DATE.in_time_zone + 1.day)
      sample
    end

    it "sends exactly one email even if the trigger fires twice for the same sample" do
      sample = eligible_toxo_sample

      expect {
        described_class.perform_now(sample.Id)
        described_class.perform_now(sample.Id)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end
end
