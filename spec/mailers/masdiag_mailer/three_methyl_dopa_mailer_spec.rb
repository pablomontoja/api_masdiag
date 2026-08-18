require "rails_helper"

RSpec.describe MasdiagMailer::ThreeMethylDopaMailer, type: :mailer do
  describe "#after_sample_registration" do
    it "does not build a mail when the patient has no email" do
      patient = create(:patient, email: nil)
      sample = create(:sample, patient: patient)

      mail = described_class.after_sample_registration(sample.Id)

      expect(mail.message).to be_a(ActionMailer::Base::NullMail)
    end
  end
end
