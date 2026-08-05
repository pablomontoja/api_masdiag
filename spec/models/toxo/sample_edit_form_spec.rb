require "rails_helper"

RSpec.describe Toxo::SampleEditForm do
  let!(:institution) { create(:institution) }
  let!(:owner)       { create(:contractor, institution_id: institution.id) }
  let!(:patient)     { create(:toxo_patient, contractor: owner) }
  let!(:project)     { create(:toxo_project_igg) }

  def build_sample(**overrides)
    ReservedSampleCode.find_or_create_by!(Code: "TX001A", InstitutionId: institution.id) do |rsc|
      rsc.IsRetailSale = true
      rsc.CreatedAt = Time.now
      rsc.expiry_date = 1.year.since
    end
    create(:toxo_sample, Code: "TX001A", patient: patient, dispatch_date: Date.today, **overrides)
  end

  def authorized_measurement_for(sample)
    Measurement.create!(SampleId: sample.Id, ProjectId: project.Id, Status: 5, MaterialType: 0, IsRepeat: false)
  end

  describe "Lot/Level" do
    it "updates Lot and Level when no measurement has been authorized" do
      sample = build_sample(Lot: "OLD", Level: "OLDLVL")
      form = described_class.new(sample: sample, contractor: owner, Lot: "NEW", Level: "NEWLVL", dispatch_date: sample.dispatch_date)

      expect(form.save).to be true
      expect(sample.reload.Lot).to eq("NEW")
      expect(sample.reload.Level).to eq("NEWLVL")
      expect(form.saved_fields).to include(:Lot, :Level)
    end

    it "rejects Lot/Level changes once a measurement has been authorized" do
      sample = build_sample(Lot: "OLD", Level: "OLDLVL")
      authorized_measurement_for(sample)
      form = described_class.new(sample: sample, contractor: owner, Lot: "NEW", Level: sample.Level, dispatch_date: sample.dispatch_date)

      expect(form.save).to be false
      expect(form.errors[:Lot]).to be_present
      expect(sample.reload.Lot).to eq("OLD")
    end

    it "rejects a blank Lot" do
      sample = build_sample(Lot: "OLD")
      form = described_class.new(sample: sample, contractor: owner, Lot: "", Level: sample.Level, dispatch_date: sample.dispatch_date)

      expect(form.save).to be false
      expect(form.errors[:Lot]).to be_present
    end

    it "rejects Lot longer than 20 characters" do
      sample = build_sample(Lot: "OLD")
      form = described_class.new(sample: sample, contractor: owner, Lot: "L" * 21, Level: sample.Level, dispatch_date: sample.dispatch_date)

      expect(form.save).to be false
      expect(form.errors[:Lot]).to be_present
    end
  end

  describe "sample_collection_date" do
    it "sets the date when it was previously blank and no result has been authorized" do
      sample = build_sample(sample_collection_date: nil, AcceptanceDate: nil)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, sample_collection_date: Date.today, dispatch_date: sample.dispatch_date)

      expect(form.save).to be true
      expect(sample.reload.sample_collection_date.to_date).to eq(Date.today)
      expect(form.saved_fields).to include(:sample_collection_date)
    end

    it "can still be set after the sample has been accepted, as long as no result is authorized" do
      sample = build_sample(sample_collection_date: nil, AcceptanceDate: 1.day.ago)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, sample_collection_date: 2.days.ago.to_date, dispatch_date: sample.dispatch_date)

      expect(form.save).to be true
      expect(sample.reload.sample_collection_date.to_date).to eq(2.days.ago.to_date)
    end

    it "allows changing an already-set date while the sample has not been accepted" do
      sample = build_sample(sample_collection_date: 2.days.ago, AcceptanceDate: nil)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, sample_collection_date: Date.today, dispatch_date: sample.dispatch_date)

      expect(form.save).to be true
      expect(sample.reload.sample_collection_date.to_date).to eq(Date.today)
    end

    it "allows changing it repeatedly even once a measurement has an authorized result, as long as not yet accepted" do
      sample = build_sample(sample_collection_date: 2.days.ago, AcceptanceDate: nil)
      authorized_measurement_for(sample)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, sample_collection_date: Date.today, dispatch_date: sample.dispatch_date)

      expect(form.save).to be true
      expect(sample.reload.sample_collection_date.to_date).to eq(Date.today)
    end

    it "rejects being changed once already set, after acceptance" do
      sample = build_sample(sample_collection_date: 3.days.ago, AcceptanceDate: 2.days.ago)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, sample_collection_date: Date.today, dispatch_date: sample.dispatch_date)

      expect(form.save).to be false
      expect(form.errors[:sample_collection_date]).to be_present
      expect(form.saved_fields).not_to include(:sample_collection_date)
    end

    it "rejects being set once a measurement has an authorized result, after acceptance" do
      sample = build_sample(sample_collection_date: nil, AcceptanceDate: 2.days.ago)
      authorized_measurement_for(sample)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, sample_collection_date: 3.days.ago.to_date, dispatch_date: sample.dispatch_date)

      expect(form.save).to be false
      expect(form.errors[:sample_collection_date]).to be_present
    end

    it "rejects a date after AcceptanceDate" do
      sample = build_sample(sample_collection_date: nil, AcceptanceDate: 3.days.ago)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, sample_collection_date: Date.today, dispatch_date: sample.dispatch_date)

      expect(form.save).to be false
      expect(form.errors[:sample_collection_date]).to be_present
    end

    it "allows a date on or before AcceptanceDate" do
      sample = build_sample(sample_collection_date: nil, AcceptanceDate: 1.day.ago)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, sample_collection_date: 2.days.ago.to_date, dispatch_date: sample.dispatch_date)

      expect(form.save).to be true
    end

    it "rejects a future date when AcceptanceDate is nil" do
      sample = build_sample(sample_collection_date: nil, AcceptanceDate: nil)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, sample_collection_date: 1.day.from_now.to_date, dispatch_date: sample.dispatch_date)

      expect(form.save).to be false
      expect(form.errors[:sample_collection_date]).to be_present
    end
  end

  describe "dispatch_date" do
    it "updates dispatch_date when the sample has not been accepted" do
      sample = build_sample(AcceptanceDate: nil, dispatch_date: 2.days.ago)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, dispatch_date: Date.today)

      expect(form.save).to be true
      expect(sample.reload.dispatch_date.to_date).to eq(Date.today)
      expect(form.saved_fields).to include(:dispatch_date)
    end

    it "rejects dispatch_date changes once the sample has been accepted" do
      sample = build_sample(AcceptanceDate: 1.day.ago, dispatch_date: 2.days.ago)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, dispatch_date: Date.today)

      expect(form.save).to be false
      expect(form.errors[:dispatch_date]).to be_present
    end

    it "rejects a blank dispatch_date" do
      sample = build_sample(dispatch_date: Date.today)
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, dispatch_date: nil)

      expect(form.save).to be false
      expect(form.errors[:dispatch_date]).to be_present
    end
  end

  describe "note" do
    it "always appends the note, even after acceptance" do
      sample = build_sample(AcceptanceDate: 1.day.ago, dispatch_date: 2.days.ago, Comment: "existing")
      form = described_class.new(sample: sample, contractor: owner, note: "new note", Lot: sample.Lot, Level: sample.Level, dispatch_date: sample.dispatch_date)

      expect(form.save).to be true
      expect(sample.reload.Comment).to include("existing")
      expect(sample.reload.Comment).to include("new note")
      expect(form.saved_fields).to include(:note)
    end

    it "does nothing when note is blank" do
      sample = build_sample(Comment: "existing")
      form = described_class.new(sample: sample, contractor: owner, Lot: sample.Lot, Level: sample.Level, note: "", dispatch_date: sample.dispatch_date)

      expect(form.save).to be true
      expect(sample.reload.Comment).to eq("existing")
    end
  end

  describe "partial save" do
    it "saves the note even when Lot is rejected" do
      sample = build_sample(Lot: "OLD", Comment: nil)
      authorized_measurement_for(sample)
      form = described_class.new(sample: sample, contractor: owner, Lot: "NEW", note: "please note", dispatch_date: sample.dispatch_date)

      expect(form.save).to be false
      expect(form.errors[:Lot]).to be_present
      sample.reload
      expect(sample.Lot).to eq("OLD")
      expect(sample.Comment).to include("please note")
      expect(form.saved_fields).to eq([ :note ])
    end
  end
end
