require "rails_helper"

RSpec.describe Note, type: :model do
  let(:sample) { create(:sample) }

  %w[
    sample-registration-confirmation-email
    sample-accepted-email
    registration-reminder-email
    registration-reminder-final-email
    sample-rejected-email
    result-available-email
  ].each do |key|
    it "accepts the notification key #{key.inspect}" do
      note = Note.new(key: key, subject: sample)
      expect(note).to be_valid
    end
  end

  it "rejects an unknown key" do
    note = Note.new(key: "totally-unknown-key", subject: sample)
    expect(note).not_to be_valid
    expect(note.errors[:key]).to be_present
  end

  it "enforces uniqueness per (subject, key)" do
    Note.create!(key: "sample-accepted-email", subject: sample)
    dup = Note.new(key: "sample-accepted-email", subject: sample)
    expect(dup).not_to be_valid
  end

  it "allows the same key on a different subject" do
    Note.create!(key: "sample-accepted-email", subject: sample)
    other = create(:sample, Code: "OTHER1")
    expect(Note.new(key: "sample-accepted-email", subject: other)).to be_valid
  end

  describe "result-available-email for a Measurement subject" do
    let(:measurement) { create(:measurement, sample: sample, project: create(:project_without_fixed_id)) }

    it "accepts result-available-email when the subject is a Measurement" do
      note = Note.new(key: "result-available-email", subject: measurement)
      expect(note).to be_valid
    end

    it "still accepts result-available-email when the subject is a Sample" do
      note = Note.new(key: "result-available-email", subject: sample)
      expect(note).to be_valid
    end

    it "allows a Sample-scoped and a Measurement-scoped Note with the same key to coexist" do
      Note.create!(key: "result-available-email", subject: sample)
      measurement_note = Note.new(key: "result-available-email", subject: measurement)
      expect(measurement_note).to be_valid
    end
  end
end
