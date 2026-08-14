require "rails_helper"

RSpec.describe Notifications::EventDispatcher do
  before { stub_const("V1::Common::TOXO_INSTITUTION_IDS", [toxo_institution.id]) }

  let(:toxo_institution) { create(:institution, name: "Toxo Inst") }
  let(:lab_institution)  { create(:institution, name: "Lab Inst") }

  def toxo_registered_sample
    contractor = create(:contractor, institution: toxo_institution,
                                     email: "doc@example.com", are_notifications_enabled: true)
    patient = create(:patient, contractor: contractor, IsVirtual: false)
    create(:sample, patient: patient)
  end

  def lab_registered_sample
    contractor = create(:contractor, institution: lab_institution,
                                     email: "lab@example.com", are_notifications_enabled: true)
    patient = create(:patient, contractor: contractor, IsVirtual: false)
    create(:sample, patient: patient)
  end

  it "routes a toxo sample to the Toxo mailer via the Sender" do
    sample = toxo_registered_sample
    expect(Toxo::SampleNotificationMailer).to receive(:result_available).with(sample).and_call_original
    expect(Notifications::Sender).to receive(:call).and_call_original

    described_class.call(event: :result_available, sample: sample)
  end

  it "routes a non-toxo sample to the existing lab mailer (delegation)" do
    sample = lab_registered_sample
    fake = double(deliver_later: true, deliver_now: true)
    expect(MasdiagMailer::ContractorResultNotificationMailer).to receive(:send_mail).and_return(fake)

    described_class.call(event: :result_available, sample: sample)
  end

  it "skips without error when no recipient can be resolved" do
    contractor = create(:contractor, institution: toxo_institution, email: "")
    patient = create(:patient, contractor: contractor, IsVirtual: false)
    sample = create(:sample, patient: patient)

    expect {
      described_class.call(event: :result_available, sample: sample)
    }.not_to change { ActionMailer::Base.deliveries.size }
  end

  it "raises / no-ops for an unknown event (no mail enqueued)" do
    sample = toxo_registered_sample
    expect {
      described_class.call(event: :sample_disposed, sample: sample)
    }.to raise_error(ArgumentError)
  end

  it "skips (no mail, no Note) when the contractor disabled that event's notification flag" do
    contractor = create(:contractor, institution: toxo_institution,
                                     email: "doc@example.com", are_notifications_enabled: true,
                                     allow_sample_acceptance_notifications: false)
    patient = create(:patient, contractor: contractor, IsVirtual: false)
    sample = create(:sample, patient: patient)

    expect {
      described_class.call(event: :sample_accepted, sample: sample)
    }.to change { ActionMailer::Base.deliveries.size }.by(0)
    expect(Note.where(subject: sample, key: "sample-accepted-email")).to be_empty
  end

  it "skips (no mail) for a non-toxo sample when the contractor disabled sample_registration_confirmation" do
    contractor = create(:contractor, institution: lab_institution,
                                     email: "lab@example.com", are_notifications_enabled: true,
                                     allow_sample_registration_notifications: false)
    patient = create(:patient, contractor: contractor, IsVirtual: false)
    sample = create(:sample, patient: patient)

    expect(MasdiagMailer::IndMailer).not_to receive(:after_sample_registration)
    result = described_class.call(event: :sample_registration_confirmation, sample: sample)
    expect(result.status).to eq(:skipped)
  end

  # FR-021: physical-only procedures (return / archive / dispose) must produce NO email.
  it "exposes only the six defined notification events and none for physical procedures" do
    expect(described_class::KNOWN_EVENTS).to contain_exactly(
      :sample_registration_confirmation, :sample_accepted, :registration_reminder,
      :registration_reminder_final, :sample_rejected, :result_available
    )
    sample = toxo_registered_sample
    %i[sample_returned sample_archived sample_disposed].each do |physical_event|
      expect {
        described_class.call(event: physical_event, sample: sample)
      }.to raise_error(ArgumentError).and change { ActionMailer::Base.deliveries.size }.by(0)
    end
  end
end
