require "rails_helper"

RSpec.describe Toxo::SampleNotificationMailer, type: :mailer do
  let(:sample) { create(:sample, Code: "TX001A") }

  describe "#result_available" do
    subject(:mail) { described_class.result_available(sample) }

    it "has the correct Polish subject" do
      expect(mail.subject).to eq("Wynik badania")
    end

    it "references the sample number and the portal URL" do
      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded
      expect(body).to include("TX001A")
      expect(body).to include(V1::Common::TOXO_PARTNER_PORTAL_URL)
    end
  end

  describe "#sample_accepted" do
    subject(:mail) { described_class.sample_accepted(sample) }

    it "has the correct Polish subject and references the sample number" do
      expect(mail.subject).to eq("Potwierdzenie przyjęcia próbki do badań")
      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded
      expect(body).to include("TX001A")
    end
  end

  describe "#registration_reminder" do
    subject(:mail) { described_class.registration_reminder(sample) }

    it "has the correct Polish subject and references portal URL" do
      expect(mail.subject).to eq("Przypomnienie o konieczności rejestracji próbki")
      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded
      expect(body).to include(V1::Common::TOXO_PARTNER_PORTAL_URL)
    end
  end

  describe "#registration_reminder_final" do
    subject(:mail) { described_class.registration_reminder_final(sample) }

    it "has the correct subject and includes the return-at-expense warning" do
      expect(mail.subject).to eq("Przypomnienie powtórne o konieczności rejestracji próbki")
      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded
      expect(body).to include("odesłana na koszt Zleceniodawcy")
    end
  end

  describe "#sample_rejected" do
    subject(:mail) { described_class.sample_rejected(sample) }

    it "has the correct subject and lists sample identification fields" do
      expect(mail.subject).to eq("Odrzucenie próbki zleconej do badań")
      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded
      expect(body).to include("Kod próbki")
      expect(body).to include("Tryb")
      expect(body).to include("Standard").or include("CITO")
    end
  end

  describe "#sample_registration_confirmation" do
    subject(:mail) { described_class.sample_registration_confirmation(sample) }

    it "has the correct subject and a PDF attachment" do
      expect(mail.subject).to eq("Potwierdzenie zlecenia badania")
      expect(mail.attachments.map(&:filename)).to include("potwierdzenie_zlecenia.pdf")
      expect(mail.attachments["potwierdzenie_zlecenia.pdf"].content_type).to include("application/pdf")
    end
  end
end
