require "rails_helper"

RSpec.describe User, type: :model do
  def build_user(attrs = {})
    User.new({
      Login: "test_user",
      Password: "irrelevant",
      Salt: "irrelevant",
      IsActive: true,
      Role: 0,
      email: "",
      HasSmartCard: false
    }.merge(attrs))
  end

  describe "translatable attributes readiness" do
    %i[FirstName LastName Description].each do |attribute|
      describe "#{attribute} — Polish locale behaves unchanged" do
        it "writes directly to the native column" do
          user = I18n.with_locale(:pl) { build_user(attribute => "wartość polska") }
          I18n.with_locale(:pl) { user.save! }
          user.reload

          expect(user.read_attribute(attribute)).to eq("wartość polska")
        end

        it "reads back the native column value" do
          user = I18n.with_locale(:pl) { build_user(attribute => "wartość polska") }
          I18n.with_locale(:pl) { user.save! }

          I18n.with_locale(:pl) { expect(user.public_send(attribute)).to eq("wartość polska") }
        end
      end

      describe "#{attribute} — English locale falls back gracefully with no translation row" do
        it "returns the Polish column value without raising" do
          user = I18n.with_locale(:pl) { build_user(attribute => "wartość polska") }
          I18n.with_locale(:pl) { user.save! }

          expect {
            I18n.with_locale(:en) { expect(user.public_send(attribute)).to eq("wartość polska") }
          }.not_to raise_error
        end
      end
    end

    it "creates zero mobility_string_translations rows for a user created under the default locale" do
      user = I18n.with_locale(:pl) { build_user(FirstName: "Jan", LastName: "Kowalski", Description: "opis") }
      I18n.with_locale(:pl) { user.save! }

      expect(user.string_translations.count).to eq(0)
    end

    it "saves FirstName/LastName/Description to native columns under the app's ambient default locale (:en), matching Project's regression guard" do
      expect(I18n.locale).to eq(:en)

      user = build_user(FirstName: "Jan", LastName: "Kowalski", Description: "opis")
      user.save!
      user.reload

      expect(user.read_attribute(:FirstName)).to eq("Jan")
      expect(user.read_attribute(:LastName)).to eq("Kowalski")
      expect(user.read_attribute(:Description)).to eq("opis")
      expect(user.string_translations).to be_empty
    end
  end

  describe "#fullname" do
    it "concatenates FirstName and LastName unchanged after the translation declaration" do
      user = I18n.with_locale(:pl) { build_user(FirstName: "Jan", LastName: "Kowalski") }

      expect(user.fullname).to eq("Jan Kowalski")
    end
  end
end
