require "rails_helper"

RSpec.describe MasdiagRecurring::DailyFftbReportMailer, type: :mailer do
  describe "#send_mail" do
    let(:csv_payload) { "Sample Code\tTest\n" }

    before do
      allow(MasdiagRecurring::FftbReportGenerator).to receive(:call)
        .and_return(OpenStruct.new(success?: true, payload: csv_payload))
    end

    subject(:mail) { described_class.send_mail }

    it "has the correct subject and recipients" do
      expect(mail.subject).to eq("FFTB Samples Report")
      expect(mail.to).to eq(["tests@foodforthebrain.org", "logistyka@masdiag.pl"])
      expect(mail.reply_to).to eq(["pawel.swider@masdiag.pl"])
    end

    it "attaches the generated CSV report" do
      filename = "masdiag-report-fftb-#{Date.today}.csv"
      expect(mail.attachments.map(&:filename)).to include(filename)
      expect(mail.attachments[filename].body.to_s).to eq(csv_payload)
    end
  end
end
