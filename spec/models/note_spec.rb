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
end
