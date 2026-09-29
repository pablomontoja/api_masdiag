require "rails_helper"

RSpec.describe Notifications::ResultAvailableSweepJob, type: :job do
  it "delegates to EventDispatcher once per Finder result" do
    m1 = instance_double(Measurement)
    m2 = instance_double(Measurement)
    allow(Notifications::UnnotifiedToxoResultsFinder).to receive(:call).and_return([m1, m2])

    expect(Notifications::EventDispatcher).to receive(:call).with(event: :result_available, measurement: m1)
    expect(Notifications::EventDispatcher).to receive(:call).with(event: :result_available, measurement: m2)

    described_class.perform_now
  end

  it "does nothing when the Finder returns no results" do
    allow(Notifications::UnnotifiedToxoResultsFinder).to receive(:call).and_return([])

    expect(Notifications::EventDispatcher).not_to receive(:call)
    described_class.perform_now
  end

  it "is configured to retry on StandardError" do
    expect(described_class.rescue_handlers.map(&:first)).to include("StandardError")
  end

  describe "integration: a real eligible unnotified Toxo measurement" do
    let(:toxo_institution) { create(:institution, name: "Toxo Inst") }

    before { stub_const("V1::Common::TOXO_INSTITUTION_IDS", [toxo_institution.id]) }

    it "sends exactly one email and creates one Note" do
      contractor = create(:contractor, institution: toxo_institution, email: "doc@example.com",
                                       are_notifications_enabled: true)
      patient = create(:patient, contractor: contractor, IsVirtual: false)
      sample = create(:sample, patient: patient)
      measurement = create(:measurement, sample: sample, project: create(:project_without_fixed_id),
                                          AuthorizedAt: Notifications::ResultAvailableJob::CUTOFF_DATE.in_time_zone + 1.day)

      expect {
        described_class.perform_now
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(Note.where(subject_type: "Measurement", subject_id: measurement.Id, key: "result-available-email")).to exist
    end
  end
end
