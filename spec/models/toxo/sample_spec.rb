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
end
