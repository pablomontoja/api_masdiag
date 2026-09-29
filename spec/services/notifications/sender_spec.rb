require "rails_helper"

RSpec.describe Notifications::Sender do
  let(:sample) { create(:sample) }
  let(:measurement) { create(:measurement, sample: sample, project: create(:project_without_fixed_id)) }
  let(:mail) do
    Toxo::SampleNotificationMailer.result_available(sample, measurement)
  end

  around do |example|
    ActiveJob::Base.queue_adapter = :test
    example.run
  end

  def call
    described_class.call(
      sample: sample,
      event: :result_available,
      family: :toxo,
      recipient: "doc@example.com",
      mail: mail
    )
  end

  it "delivers the mail" do
    expect { call }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end

  it "creates a Note with the event key and family in the description" do
    call
    note = Note.find_by(subject: sample, key: "result-available-email")
    expect(note).to be_present
    expect(note.description.to_s).to match(/toxo/i)
  end

  it "writes a ResultSendingEvent audit record (sent_through EmailNotification=1)" do
    expect { call }.to change { ResultSendingEvent.where(sample_id: sample.Id).count }.by(1)
    event = ResultSendingEvent.where(sample_id: sample.Id).last
    expect(event.sent_through).to eq(1)
    expect(event.address).to eq("doc@example.com")
    expect(event.db_files).to be_present
  end

  it "is idempotent — a second call sends nothing and creates no second Note" do
    call
    expect {
      described_class.call(sample: sample, event: :result_available, family: :toxo,
                           recipient: "doc@example.com", mail: mail)
    }.to change { ActionMailer::Base.deliveries.size }.by(0)
      .and change { Note.where(subject: sample, key: "result-available-email").count }.by(0)
  end

  it "skips (no email, no error) when recipient is blank" do
    expect {
      described_class.call(sample: sample, event: :result_available, family: :toxo,
                           recipient: nil, mail: mail)
    }.to change { ActionMailer::Base.deliveries.size }.by(0)
    expect(Note.where(subject: sample, key: "result-available-email")).to be_empty
  end

  describe "measurement-scoped idempotency (US1)" do
    let(:measurement) { create(:measurement, sample: sample, project: create(:project_without_fixed_id)) }
    let(:other_measurement) { create(:measurement, sample: sample, project: create(:project_without_fixed_id)) }

    def call_for(m)
      described_class.call(
        measurement: m,
        event: :result_available,
        family: :toxo,
        recipient: "doc@example.com",
        mail: Toxo::SampleNotificationMailer.result_available(sample, m)
      )
    end

    it "creates a Note with subject: measurement, not subject: measurement.sample" do
      call_for(measurement)
      expect(Note.find_by(subject_type: "Measurement", subject_id: measurement.Id, key: "result-available-email")).to be_present
      expect(Note.where(subject_type: "Sample", subject_id: sample.Id, key: "result-available-email")).to be_empty
    end

    it "is idempotent per measurement — a second call for the SAME measurement sends nothing new" do
      call_for(measurement)
      expect { call_for(measurement) }.to change { ActionMailer::Base.deliveries.size }.by(0)
    end

    it "dispatches independently for a DIFFERENT measurement on the same sample" do
      call_for(measurement)
      expect { call_for(other_measurement) }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(Note.where(subject_type: "Measurement", key: "result-available-email").pluck(:subject_id))
        .to contain_exactly(measurement.Id, other_measurement.Id)
    end
  end
end
