require "rails_helper"

RSpec.describe MasdiagMailer::IndMailer, type: :mailer do
  describe "#after_sample_registration" do
    it "does not build a mail when the patient has no email" do
      patient = create(:patient, email: nil)
      sample = create(:sample, patient: patient)

      mail = described_class.after_sample_registration(sample.Id)

      expect(mail.message).to be_a(ActionMailer::Base::NullMail)
    end

    it "sends to the patient's email when present" do
      patient = create(:patient, email: "patient@example.com")
      sample = create(:sample, patient: patient)

      mail = described_class.after_sample_registration(sample.Id)

      expect(mail.to).to eq(["patient@example.com"])
    end
  end

  describe "#shipping_after_new_order" do
    it "includes the ShopOrder's source in the subject and body" do
      shop_order = create(:shop_order, source: "shopify")

      mail = described_class.shipping_after_new_order(shop_order.id)

      expect(mail.subject).to include("shopify")
      expect(mail.body.encoded).to include("shopify")
    end

    it "attaches the Diagnostyka Precyzyjna logo for a wordpress-sourced order" do
      shop_order = create(:shop_order, source: "wordpress")

      mail = described_class.shipping_after_new_order(shop_order.id)

      expect(mail.attachments.map(&:filename)).to include("logo_dp.png")
      expect(mail.attachments.map(&:filename)).not_to include("logo-rare-diagnostics.png")
    end

    it "attaches the Rare Disease Diagnostics logo for a shopify-sourced order" do
      shop_order = create(:shop_order, source: "shopify")

      mail = described_class.shipping_after_new_order(shop_order.id)

      expect(mail.attachments.map(&:filename)).to include("logo-rare-diagnostics.png")
      expect(mail.attachments.map(&:filename)).not_to include("logo_dp.png")
    end
  end

  describe "#after_new_order_save" do
    context "when the ShopOrder is wordpress-sourced" do
      it "sends the Polish diagnostykaprecyzyjna.pl email" do
        shop_order = create(:shop_order, source: "wordpress", email: "customer@example.com")

        mail = described_class.after_new_order_save(shop_order.id)
        html = mail.html_part.body.decoded

        expect(mail.subject).to eq("Diagnostyka Precyzyjna - Rejestracja Testów")
        expect(html).to include("Dziękujemy za zamówienie")
        expect(html).to include("diagnostykaprecyzyjna.pl")
        expect(html).not_to include("Thank you for your order")
        expect(html).not_to include("Rare Disease Diagnostics")
      end
    end

    context "when the ShopOrder is shopify-sourced" do
      it "sends the English Rare Disease Diagnostics email" do
        shop_order = create(:shop_order, source: "shopify", email: "customer@example.com")

        mail = described_class.after_new_order_save(shop_order.id)
        html = mail.html_part.body.decoded

        expect(mail.subject).to eq("Rare Disease Diagnostics - Test Registration")
        expect(html).to include("Thank you for your order")
        expect(html).to include("results.rarediagnostics.eu")
        expect(html).not_to include("Dziękujemy za zamówienie")
        expect(html).not_to include("diagnostykaprecyzyjna.pl")
      end
    end
  end
end
