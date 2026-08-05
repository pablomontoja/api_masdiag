require "rails_helper"

RSpec.describe Toxo::Sample, type: :model do
  describe "Lot validation" do
    it "is invalid when Lot is blank" do
      sample = build(:toxo_sample, Lot: "")
      sample.valid?
      expect(sample.errors[:Lot]).to be_present
    end

    it "is invalid when Lot exceeds 20 characters" do
      sample = build(:toxo_sample, Lot: "L" * 21)
      sample.valid?
      expect(sample.errors[:Lot]).to be_present
    end

    it "is valid when Lot is present and within 20 characters" do
      sample = build(:toxo_sample, Lot: "L" * 20)
      sample.valid?
      expect(sample.errors[:Lot]).to be_empty
    end
  end

  describe "Level validation" do
    it "is valid when Level is blank" do
      sample = build(:toxo_sample, Level: nil)
      sample.valid?
      expect(sample.errors[:Level]).to be_empty
    end

    it "is invalid when Level exceeds 20 characters" do
      sample = build(:toxo_sample, Level: "L" * 21)
      sample.valid?
      expect(sample.errors[:Level]).to be_present
    end

    it "is valid when Level is present and within 20 characters" do
      sample = build(:toxo_sample, Level: "L" * 20)
      sample.valid?
      expect(sample.errors[:Level]).to be_empty
    end
  end

  describe "#sample_collection_date_editable?" do
    let!(:project) { create(:toxo_project_igg) }

    def authorized_measurement_for(sample)
      Measurement.create!(SampleId: sample.Id, ProjectId: project.Id, Status: 5, MaterialType: 0, IsRepeat: false)
    end

    context "before acceptance (AcceptanceDate is nil)" do
      it "is true when blank and date is within bounds" do
        sample = create(:toxo_sample, AcceptanceDate: nil, sample_collection_date: nil)
        expect(sample.sample_collection_date_editable?(Date.current)).to be true
      end

      it "is true even when already set — repeatedly editable, not just a one-time fill-in" do
        sample = create(:toxo_sample, AcceptanceDate: nil, sample_collection_date: 2.days.ago)
        expect(sample.sample_collection_date_editable?(Date.current)).to be true
      end

      it "is true even once a measurement has an authorized result — result status does not gate this phase" do
        sample = create(:toxo_sample, AcceptanceDate: nil, sample_collection_date: nil)
        authorized_measurement_for(sample)
        expect(sample.sample_collection_date_editable?(Date.current)).to be true
      end

      it "is false for a future date" do
        sample = create(:toxo_sample, AcceptanceDate: nil, sample_collection_date: nil)
        expect(sample.sample_collection_date_editable?(1.day.from_now.to_date)).to be false
      end

      it "is false for a blank date" do
        sample = create(:toxo_sample, AcceptanceDate: nil, sample_collection_date: nil)
        expect(sample.sample_collection_date_editable?(nil)).to be false
      end
    end

    context "after acceptance (AcceptanceDate present)" do
      it "is true when blank and no result has been authorized" do
        sample = create(:toxo_sample, AcceptanceDate: 2.days.ago, sample_collection_date: nil)
        expect(sample.sample_collection_date_editable?(3.days.ago.to_date)).to be true
      end

      it "is false when sample_collection_date was already set" do
        sample = create(:toxo_sample, AcceptanceDate: 2.days.ago, sample_collection_date: 3.days.ago)
        expect(sample.sample_collection_date_editable?(Date.current)).to be false
      end

      it "is false once a measurement has an authorized result" do
        sample = create(:toxo_sample, AcceptanceDate: 2.days.ago, sample_collection_date: nil)
        authorized_measurement_for(sample)
        expect(sample.sample_collection_date_editable?(3.days.ago.to_date)).to be false
      end

      it "is false for a date after AcceptanceDate" do
        sample = create(:toxo_sample, AcceptanceDate: 2.days.ago, sample_collection_date: nil)
        expect(sample.sample_collection_date_editable?(Date.current)).to be false
      end

      it "is false for a blank date" do
        sample = create(:toxo_sample, AcceptanceDate: 2.days.ago, sample_collection_date: nil)
        expect(sample.sample_collection_date_editable?(nil)).to be false
      end
    end
  end
end
