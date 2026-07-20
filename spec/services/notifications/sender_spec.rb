require "rails_helper"

RSpec.describe Notifications::Sender do
  let(:sample) { create(:sample) }
  let(:mail) do
    Toxo::SampleNotificationMailer.result_available(sample)
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
end
