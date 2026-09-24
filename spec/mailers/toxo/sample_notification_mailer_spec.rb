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

    it "renders the sample's measurement in the table" do
      project = create(:project_without_fixed_id, Name: "Analiza specjalna")
      create(:measurement, sample: sample, project: project)

      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded

      expect(body).to include("Analiza specjalna")
    end

    it "renders the Polish measurement name even when I18n.default_locale is :en" do
      expect(I18n.default_locale).to eq(:en) # dokumentuje istniejącą konfigurację aplikacji
      project = create(:project_without_fixed_id, Name: "Nazwa polska")
      create(:measurement, sample: sample, project: project)

      I18n.with_locale(:en) do
        delivered = described_class.result_available(sample.reload)
        body = delivered.html_part ? delivered.html_part.body.encoded : delivered.body.encoded
        expect(body).to include("Nazwa polska")
      end
    end

    it "renders a textual (Polish) status label instead of the raw integer" do
      project = create(:project_without_fixed_id)
      create(:measurement, sample: sample, project: project, Status: 5)

      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded

      expect(body).to include("autoryzowany wynik")
    end

    it "falls back to the raw status when no label is defined for it" do
      project = create(:project_without_fixed_id)
      create(:measurement, sample: sample, project: project, Status: 99)

      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded

      expect(body).to include(">99<")
    end

    context "with a sample that has multiple measurements in different states" do
      let(:project_with_pdf)          { create(:project_without_fixed_id, Name: "Toxo IgG") }
      let(:project_without_pdf_yet)   { create(:project_without_fixed_id, Name: "Toxo IgM") }
      let(:project_not_yet_authorized) { create(:project_without_fixed_id, Name: "Toxo na zlecenie") }

      let!(:measurement_with_pdf) do
        m = create(:measurement, sample: sample, project: project_with_pdf, Status: 5, AuthorizedAt: 1.day.ago)
        create(:online_file, measurement: m, file_contents: "%PDF-1.4 fake pdf bytes", filename: "wynik.pdf")
        m.reload
      end
      let!(:measurement_without_pdf_yet) do
        create(:measurement, sample: sample, project: project_without_pdf_yet, Status: 5, AuthorizedAt: 1.day.ago)
      end
      let!(:measurement_not_yet_authorized) do
        create(:measurement, sample: sample, project: project_not_yet_authorized, Status: 1, AuthorizedAt: nil)
      end

      it "renders a table row for every measurement on the sample, regardless of status" do
        body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded

        expect(body).to include("Toxo IgG")
        expect(body).to include("Toxo IgM")
        expect(body).to include("Toxo na zlecenie")
      end

      it "renders a working PDF link for every measurement that has an available report (SC-004)" do
        body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded

        expect(body).to include(measurement_with_pdf.report_pdf_url)
      end

      it "does not render a link for a measurement with no PDF available yet" do
        body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded

        expect(measurement_without_pdf_yet.report_pdf_url).to be_nil
        expect(body.scan(measurement_without_pdf_yet.AuthorizedAt.strftime("%Y")).any?).to be true
      end

      it "shows no authorization date and no PDF link for a not-yet-authorized measurement" do
        expect(measurement_not_yet_authorized.report_pdf_url).to be_nil
        expect(measurement_not_yet_authorized.AuthorizedAt).to be_nil
      end
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

  describe "#chromatogram_request" do
    let!(:toxo_project_igg) { create(:toxo_project_igg) }
    let(:institution) { create(:institution) }
    let(:contractor)  { create(:contractor, institution_id: institution.id, email: "kontrahent@example.com") }
    let(:toxo_patient) { create(:toxo_patient, contractor: contractor) }
    let(:toxo_sample) { create(:toxo_sample, Code: "TX001A", patient: toxo_patient) }
    let(:measurement) do
      Measurement.create!(SampleId: toxo_sample.Id, ProjectId: 39, Status: 5, MaterialType: 0, IsRepeat: false)
    end

    subject(:mail) { described_class.chromatogram_request(measurement, contractor) }

    it "is addressed to the laboratory's request-handling inbox" do
      expect(mail.to).to include("toxo@masdiag.pl")
    end

    it "has the correct Polish subject and includes contractor email, sample code, and test name" do
      expect(mail.subject).to eq("Prośba o chromatogram")
      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded
      expect(body).to include("kontrahent@example.com")
      expect(body).to include("TX001A")
      expect(body).to include(Toxo::Constants::PROJECT_NAMES[39])
    end
  end

  describe "#on_request_measurement" do
    let!(:toxo_project_on_request) { create(:toxo_project_on_request) }
    let(:institution) { create(:institution) }
    let(:contractor)  { create(:contractor, institution_id: institution.id, email: "kontrahent@example.com") }
    let(:toxo_patient) { create(:toxo_patient, contractor: contractor) }
    let(:toxo_sample) { create(:toxo_sample, Code: "TX001A", patient: toxo_patient, Comment: "Proszę o dodatkowe badanie") }
    let(:measurement) do
      Measurement.create!(SampleId: toxo_sample.Id, ProjectId: 42, Status: 1, MaterialType: 0, IsRepeat: false)
    end

    subject(:mail) { described_class.on_request_measurement(measurement, contractor) }

    it "is addressed to the laboratory's request-handling inbox" do
      expect(mail.to).to include("toxo@masdiag.pl")
    end

    it "has the correct Polish subject and includes contractor email, sample code, and the request note" do
      expect(mail.subject).to eq("Zgłoszono badanie na zlecenie")
      body = mail.html_part ? mail.html_part.body.encoded : mail.body.encoded
      expect(body).to include("kontrahent@example.com")
      expect(body).to include("TX001A")
      expect(body).to include("Proszę o dodatkowe badanie")
    end
  end
end
