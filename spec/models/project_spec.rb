require "rails_helper"

RSpec.describe Project, type: :model do
  describe "Name translation" do
    describe "default (no explicit locale) — writes to column" do
      it "saves to Projects.Name column under the app's ambient default locale (:en) without requiring an explicit :pl wrap" do
        # Regression guard: config.i18n.default_locale is :en, and specs run under I18n.locale = :en
        # (spec/rails_helper.rb) unless wrapped. A bare `create(:project, ...)` — used across dozens of
        # other spec files — must still land in the native column, never route into Mobility by accident.
        expect(I18n.locale).to eq(:en)

        project = create(:project_without_fixed_id, Name: "domyślna nazwa")

        expect(project.read_attribute(:Name)).to eq("domyślna nazwa")
        expect(project.string_translations).to be_empty
      end
    end

    describe "Polish locale — writes to column" do
      it "saves directly to Projects.Name column and not to mobility_string_translations" do
        project = I18n.with_locale(:pl) { create(:project_without_fixed_id, Name: "oryginalna nazwa") }

        I18n.with_locale(:pl) { project.update!(Name: "polska nazwa") }
        project.reload

        expect(project.read_attribute(:Name)).to eq("polska nazwa")
        pl_rows = project.string_translations.where(key: "Name", locale: "pl")
        expect(pl_rows).to be_empty
      end

      it "reads back Polish value from the column" do
        project = I18n.with_locale(:pl) { create(:project_without_fixed_id, Name: "polska nazwa") }

        I18n.with_locale(:pl) { expect(project.Name).to eq("polska nazwa") }
      end
    end

    describe "English locale — writes to mobility_string_translations only via explicit locale: kwarg" do
      it "saves to mobility_string_translations and leaves the column untouched" do
        project = create(:project_without_fixed_id, Name: "polska nazwa")
        original_column = project.read_attribute(:Name)

        project.public_send(:Name=, "English name", locale: :en)
        project.save!

        expect(project.read_attribute(:Name)).to eq(original_column)
        en_row = project.string_translations.find_by(key: "Name", locale: "en")
        expect(en_row&.value).to eq("English name")
      end

      it "reads back English value from mobility_string_translations" do
        project = create(:project_without_fixed_id, Name: "polska nazwa")
        project.public_send(:Name=, "English name", locale: :en)
        project.save!
        project.reload

        I18n.with_locale(:en) { expect(project.Name).to eq("English name") }
      end

      it "falls back to the Polish column value when no English translation exists" do
        project = create(:project_without_fixed_id, Name: "polska nazwa")

        I18n.with_locale(:en) { expect(project.Name).to eq("polska nazwa") }
      end

      it "does NOT create a translation row for a plain update! under ambient :en with no explicit locale: kwarg" do
        project = create(:project_without_fixed_id, Name: "polska nazwa")

        I18n.with_locale(:en) { project.update!(Name: "still native") }

        expect(project.read_attribute(:Name)).to eq("still native")
        expect(project.string_translations).to be_empty
      end
    end

    describe "locale isolation" do
      it "keeps Polish column value and English translation independent after both are set" do
        project = create(:project_without_fixed_id, Name: "polska nazwa")
        project.public_send(:Name=, "English name", locale: :en)
        project.save!

        expect(project.read_attribute(:Name)).to eq("polska nazwa")
        en_row = project.string_translations.find_by(key: "Name", locale: "en")
        expect(en_row&.value).to eq("English name")
      end
    end
  end
end
