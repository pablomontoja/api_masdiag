require "rails_helper"

RSpec.describe Analyte, type: :model do
  let(:project) { create(:project_without_fixed_id) }

  describe "NameInReport hybrid storage" do
    describe "Polish locale — writes to column" do
      it "saves directly to Analytes.NameInReport column and not to mobility_string_translations" do
        analyte = I18n.with_locale(:pl) { create(:analyte, project: project, NameInReport: "oryginalna nazwa") }

        I18n.with_locale(:pl) { analyte.update!(NameInReport: "polska nazwa") }
        analyte.reload

        expect(analyte.read_attribute(:NameInReport)).to eq("polska nazwa")
        pl_rows = analyte.string_translations.where(key: "NameInReport", locale: "pl")
        expect(pl_rows).to be_empty
      end

      it "reads back Polish value from the column" do
        analyte = I18n.with_locale(:pl) { create(:analyte, project: project, NameInReport: "polska nazwa") }

        I18n.with_locale(:pl) { expect(analyte.NameInReport).to eq("polska nazwa") }
      end

    end

    describe "English locale — writes to mobility_string_translations" do
      it "saves to mobility_string_translations and leaves the column untouched" do
        analyte = I18n.with_locale(:pl) { create(:analyte, project: project, NameInReport: "polska nazwa") }
        original_column = analyte.read_attribute(:NameInReport)

        I18n.with_locale(:en) { analyte.update!(NameInReport: "English name") }

        expect(analyte.read_attribute(:NameInReport)).to eq(original_column)
        en_row = analyte.string_translations.find_by(key: "NameInReport", locale: "en")
        expect(en_row&.value).to eq("English name")
      end

      it "reads back English value from mobility_string_translations" do
        analyte = I18n.with_locale(:pl) { create(:analyte, project: project, NameInReport: "polska nazwa") }
        I18n.with_locale(:en) { analyte.update!(NameInReport: "English name") }
        analyte.reload

        I18n.with_locale(:en) { expect(analyte.NameInReport).to eq("English name") }
      end
    end

    describe "locale isolation" do
      it "keeps Polish column value and English translation independent after both are set" do
        analyte = I18n.with_locale(:pl) { create(:analyte, project: project, NameInReport: "polska nazwa") }
        I18n.with_locale(:en) { analyte.update!(NameInReport: "English name") }

        expect(analyte.read_attribute(:NameInReport)).to eq("polska nazwa")
        en_row = analyte.string_translations.find_by(key: "NameInReport", locale: "en")
        expect(en_row&.value).to eq("English name")
      end
    end
  end
end
