require "rails_helper"

RSpec.describe MasdiagRecurring::Daily::OmegaquantCsvResultsJob, type: :job do
  let!(:omegaquant_institution) { create(:institution, name: "OmegaQuant Analytics") }
  let(:contractor) { create(:contractor, institution: omegaquant_institution) }
  let(:patient) { create(:patient, contractor: contractor) }
  let!(:sample) { create(:sample, Code: "OQ1", patient: patient, AcceptanceDate: Time.current) }
  let!(:measurement) { create(:measurement, sample: sample, Status: 5) }

  it "delivers the CSV results mail for eligible measurements" do
    mail = instance_double(ActionMailer::MessageDelivery)
    allow(MasdiagRecurring::DailyOmegaquantCsvResultsMailer).to receive(:daily_mail).with([measurement.Id]).and_return(mail)
    expect(mail).to receive(:deliver_later)

    described_class.perform_now
  end

  it "excludes measurements already settled via a Note" do
    Note.create!(key: "omegaquant-result-exit-in-csv", subject: measurement, description: "already sent")

    expect(MasdiagRecurring::DailyOmegaquantCsvResultsMailer).not_to receive(:daily_mail)

    described_class.perform_now
  end

  it "does nothing when there are no eligible measurements" do
    sample.update_column(:AcceptanceDate, nil)

    expect(MasdiagRecurring::DailyOmegaquantCsvResultsMailer).not_to receive(:daily_mail)

    described_class.perform_now
  end

  it "is configured to retry on StandardError" do
    expect(described_class.rescue_handlers.map(&:first)).to include("StandardError")
  end
end
