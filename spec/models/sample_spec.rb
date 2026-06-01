require "rails_helper"

RSpec.describe Sample, type: :model do
  describe "#sample_collection_date_range" do
    let!(:package) { create(:package, product: create(:product)) }

    context "for Lalen institution" do
      let!(:inst) { create(:institution, id: V1::Common::LALEN_INSTITUTION_IDS.first) }
      let!(:rsc) { create(:reserved_sample_code, Code: "JV4XJ", InstitutionId: inst.id, package_id: package.id) }
      let(:sample) { build(:sample, Code: "JV4XJ", sample_collection_date: Date.today) }

      it "is invalid when sample_collection_date is older than 6 weeks" do
        sample.sample_collection_date = 7.weeks.ago.to_date
        expect(sample.valid?).to be false
        expect(sample.errors[:sample_collection_date]).to be_present
      end

      it "is invalid when sample_collection_date is in the future" do
        sample.sample_collection_date = 1.day.from_now.to_date
        expect(sample.valid?).to be false
        expect(sample.errors[:sample_collection_date]).to be_present
      end

      it "is valid when sample_collection_date is today" do
        sample.sample_collection_date = Date.today
        expect(sample.errors[:sample_collection_date]).to be_empty
      end

      it "is valid when sample_collection_date is exactly 6 weeks ago" do
        sample.sample_collection_date = 6.weeks.ago.to_date
        expect(sample.errors[:sample_collection_date]).to be_empty
      end
    end

    context "for non-Lalen institution" do
      let!(:inst) { create(:institution) }
      let!(:rsc) { create(:reserved_sample_code, Code: "JV4XJ", InstitutionId: inst.id, package_id: package.id) }
      let(:sample) { build(:sample, Code: "JV4XJ") }

      it "is valid when sample_collection_date is older than 6 weeks" do
        sample.sample_collection_date = 7.weeks.ago.to_date
        expect(sample.errors[:sample_collection_date]).to be_empty
      end
    end
  end
end
