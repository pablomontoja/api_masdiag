require "rails_helper"

RSpec.describe Toxo::SamplePolicy do
  let!(:institution) { create(:institution) }
  let!(:owner)       { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:patient)     { create(:toxo_patient, contractor: owner) }

  def build_sample(**overrides)
    build(:toxo_sample, patient: patient, **overrides)
  end

  describe "#update?" do
    it "is true for the owner with an eligible order" do
      sample = build_sample(AcceptanceDate: nil)
      expect(described_class.new(owner, sample).update?).to be true
    end

    it "is true even once the order has been accepted (Comment remains always editable; per-field rules live in Toxo::SampleEditForm)" do
      sample = build_sample(AcceptanceDate: Time.current)
      expect(described_class.new(owner, sample).update?).to be true
    end

    it "is false for a non-owning contractor" do
      other_contractor = create(:contractor, institution_id: institution.id)
      sample = build_sample(AcceptanceDate: nil)
      expect(described_class.new(other_contractor, sample).update?).to be false
    end

    it "is false when the contractor cannot add samples" do
      owner.can_add_samples = false
      sample = build_sample(AcceptanceDate: nil)
      expect(described_class.new(owner, sample).update?).to be false
    end

    it "is true for a held order that has not been accepted" do
      sample = build_sample(AcceptanceDate: nil, SampleStatus: 3)
      expect(described_class.new(owner, sample).update?).to be true
    end
  end
end
