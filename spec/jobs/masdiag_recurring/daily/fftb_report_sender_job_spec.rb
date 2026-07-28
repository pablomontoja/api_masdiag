require "rails_helper"

RSpec.describe MasdiagRecurring::Daily::FftbReportSenderJob, type: :job do
  it "delivers the FFTB daily report mail" do
    mail = instance_double(ActionMailer::MessageDelivery)
    allow(MasdiagRecurring::DailyFftbReportMailer).to receive(:send_mail).and_return(mail)
    expect(mail).to receive(:deliver_later)

    described_class.perform_now
  end

  it "is configured to retry on StandardError" do
    expect(described_class.rescue_handlers.map(&:first)).to include("StandardError")
  end
end
