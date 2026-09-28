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

  def measurement_for(sample)
    create(:measurement, sample: sample, project: create(:project_without_fixed_id))
  end

  it "routes a toxo measurement to the Toxo mailer via the Sender" do
    sample = toxo_registered_sample
    measurement = measurement_for(sample)
    expect(Toxo::SampleNotificationMailer).to receive(:result_available).with(sample, measurement).and_call_original
    expect(Notifications::Sender).to receive(:call).and_call_original

    described_class.call(event: :result_available, measurement: measurement)
  end

  it "routes a non-toxo measurement to the existing lab mailer (delegation)" do
    sample = lab_registered_sample
    measurement = measurement_for(sample)
    create(:online_file, measurement: measurement, is_notification_send: false)
    fake = double(deliver_later: true, deliver_now: true)
    expect(MasdiagMailer::ContractorResultNotificationMailer).to receive(:send_mail).and_return(fake)

    described_class.call(event: :result_available, measurement: measurement)
  end

  it "skips without error when no recipient can be resolved" do
    contractor = create(:contractor, institution: toxo_institution, email: "")
    patient = create(:patient, contractor: contractor, IsVirtual: false)
    sample = create(:sample, patient: patient)
    measurement = measurement_for(sample)

    expect {
      described_class.call(event: :result_available, measurement: measurement)
    }.not_to change { ActionMailer::Base.deliveries.size }
  end

  it "raises ArgumentError when :result_available is called without measurement:" do
    sample = toxo_registered_sample
    expect {
      described_class.call(event: :result_available, sample: sample)
    }.to raise_error(ArgumentError)
  end

  it "raises ArgumentError when a non-result_available event is called without sample:" do
    sample = toxo_registered_sample
    measurement = measurement_for(sample)
    expect {
      described_class.call(event: :sample_accepted, measurement: measurement)
    }.to raise_error(ArgumentError)
  end

  describe "dispatch_lab unsent-files guard (US3)" do
    it "sends no email and does not call the mailer when all files for the sample are already notified" do
      sample = lab_registered_sample
      measurement = measurement_for(sample)
      create(:online_file, measurement: measurement, is_notification_send: true)

      expect(MasdiagMailer::ContractorResultNotificationMailer).not_to receive(:send_mail)

      result = described_class.call(event: :result_available, measurement: measurement)
      expect(result.status).to eq(:skipped)
    end

    it "includes only the unsent file when the sample has a mix of sent and unsent files" do
      sample = lab_registered_sample
      m1 = measurement_for(sample)
      m2 = measurement_for(sample)
      create(:online_file, measurement: m1, is_notification_send: true)
      unsent_file = create(:online_file, measurement: m2, is_notification_send: false)

      expect(MasdiagMailer::ContractorResultNotificationMailer)
        .to receive(:send_mail).with(anything, [unsent_file.measurement_id]).and_return(double(deliver_later: true))

      described_class.call(event: :result_available, measurement: m2)
    end
  end

  it "dispatches independently for two different measurements on the same sample (US1 regression)" do
    sample = toxo_registered_sample
    m1 = measurement_for(sample)
    m2 = measurement_for(sample)

    expect {
      described_class.call(event: :result_available, measurement: m1)
      described_class.call(event: :result_available, measurement: m2)
    }.to change { ActionMailer::Base.deliveries.size }.by(2)

    expect(Note.where(subject_type: "Measurement", key: "result-available-email").pluck(:subject_id))
      .to contain_exactly(m1.Id, m2.Id)
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
