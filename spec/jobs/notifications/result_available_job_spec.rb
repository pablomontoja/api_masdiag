require "rails_helper"

RSpec.describe Notifications::ResultAvailableJob, type: :job do
  let(:sample) { create(:sample) }

  context "when the measurement is eligible (AuthorizedAt on/after CUTOFF_DATE)" do
    let(:measurement) do
      create(:measurement, sample: sample, project: create(:project_without_fixed_id),
                            AuthorizedAt: described_class::CUTOFF_DATE.in_time_zone + 1.day)
    end

    it "delegates to EventDispatcher with event :result_available" do
      expect(Notifications::EventDispatcher).to receive(:call).with(event: :result_available, measurement: measurement)
      described_class.perform_now(measurement.Id)
    end
  end

  context "when the measurement is ineligible (AuthorizedAt nil)" do
    let(:measurement) do
      create(:measurement, sample: sample, project: create(:project_without_fixed_id), AuthorizedAt: nil)
    end

    it "does not dispatch and sends no email" do
      expect(Notifications::EventDispatcher).not_to receive(:call)
      expect {
        described_class.perform_now(measurement.Id)
      }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  context "when the measurement is authorized before CUTOFF_DATE" do
    let(:measurement) do
      create(:measurement, sample: sample, project: create(:project_without_fixed_id),
                            AuthorizedAt: described_class::CUTOFF_DATE.in_time_zone - 1.day)
    end

    it "does not dispatch and sends no email" do
      expect(Notifications::EventDispatcher).not_to receive(:call)
      expect {
        described_class.perform_now(measurement.Id)
      }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  it "does nothing for a missing measurement" do
    expect(Notifications::EventDispatcher).not_to receive(:call)
    described_class.perform_now(999_999)
  end

  it "is configured to retry on StandardError" do
    expect(described_class.rescue_handlers.map(&:first)).to include("StandardError")
  end

  describe "measurement-scoped idempotency and multi-measurement dispatch (FR-002, US1)" do
    let(:toxo_institution) { create(:institution, name: "Toxo Inst") }

    before { stub_const("V1::Common::TOXO_INSTITUTION_IDS", [toxo_institution.id]) }

    def eligible_toxo_sample
      contractor = create(:contractor, institution: toxo_institution, email: "doc@example.com",
                                       are_notifications_enabled: true)
      patient = create(:patient, contractor: contractor, IsVirtual: false)
      create(:sample, patient: patient)
    end

    def eligible_measurement(sample)
      create(:measurement, sample: sample, project: create(:project_without_fixed_id),
                            AuthorizedAt: described_class::CUTOFF_DATE.in_time_zone + 1.day)
    end

    it "sends exactly one email even if the trigger fires twice for the same measurement" do
      sample = eligible_toxo_sample
      measurement = eligible_measurement(sample)

      expect {
        described_class.perform_now(measurement.Id)
        described_class.perform_now(measurement.Id)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

    it "sends a SECOND, distinct email for a second measurement on the same sample (bug-report regression)" do
      sample = eligible_toxo_sample
      m1 = eligible_measurement(sample)
      m2 = eligible_measurement(sample)

      expect {
        described_class.perform_now(m1.Id)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect {
        described_class.perform_now(m2.Id)
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(Note.where(subject_type: "Measurement", key: "result-available-email").pluck(:subject_id))
        .to contain_exactly(m1.Id, m2.Id)
    end
  end
end
