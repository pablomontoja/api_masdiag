require "rails_helper"

RSpec.describe MasdiagRecurring::DailyOmegaquantCsvResultsMailer, type: :mailer do
  describe "#daily_mail" do
    let!(:measurement) { create(:measurement) }
    let(:csv_payload) { "Sample code\tvitamin_d [ng/ml]\n" }

    before do
      allow(MasdiagRecurring::OmegaquantCsvResultsGenerator).to receive(:call)
        .and_return(OpenStruct.new(success?: true, payload: { csv: csv_payload, measurement_ids: [measurement.Id] }))
    end

    subject(:mail) { described_class.daily_mail([measurement.Id]) }

    it "has the correct subject and recipients" do
      expect(mail.subject).to eq("CSV Results")
      expect(mail.to).to eq(["jason@omegaquant.com"])
      expect(mail.cc).to eq(["james@omegaquant.com"])
      expect(mail.bcc).to eq(["pawel.swider@masdiag.pl"])
    end

    it "attaches the generated CSV" do
      filename = "results-#{Date.today.strftime('%Y-%m-%d')}.csv"
      expect(mail.attachments.map(&:filename)).to include(filename)
      expect(mail.attachments[filename].body.to_s).to eq(csv_payload)
    end

    it "creates an idempotency Note for each settled measurement" do
      expect { mail.deliver_now }.to change {
        Note.where(key: "omegaquant-result-exit-in-csv", subject_type: "Measurement", subject_id: measurement.Id).count
      }.from(0).to(1)
    end
  end
end
