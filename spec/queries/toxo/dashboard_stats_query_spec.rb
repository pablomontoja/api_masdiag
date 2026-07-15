require "rails_helper"

RSpec.describe Toxo::DashboardStatsQuery do
  let!(:institution) { create(:institution) }
  let!(:contractor)  { create(:contractor, institution_id: institution.id, can_add_samples: true, is_super_contractor: false) }
  let!(:toxo_patient) { create(:toxo_patient, contractor: contractor) }

  describe "#call" do
    it "defaults an invalid window to 30" do
      stats = described_class.new(user: contractor, window: "not-a-number").call
      expect(stats[:window]).to eq(30)
    end

    it "accepts each allowed window value" do
      [ 30, 90, 180, 360 ].each do |window|
        stats = described_class.new(user: contractor, window: window).call
        expect(stats[:window]).to eq(window)
      end
    end

    it "returns a hash with all expected keys" do
      stats = described_class.new(user: contractor, window: 30).call

      expect(stats.keys).to contain_exactly(
        :window, :orders_count, :authorized_measurements_count,
        :unused_reserved_codes_count, :orders_series, :authorized_series, :analysis_breakdown
      )
    end

    it "excludes samples registered outside the window" do
      sample = create(:toxo_sample, Code: "TX001A", patient: toxo_patient)
      sample.update_column(:RegistrationDate, 45.days.ago)

      stats = described_class.new(user: contractor, window: 30).call
      expect(stats[:orders_count]).to eq(0)

      stats_90 = described_class.new(user: contractor, window: 90).call
      expect(stats_90[:orders_count]).to eq(1)
    end

    it "excludes non-authorized measurements from the authorized count" do
      sample = create(:toxo_sample, Code: "TX001A", patient: toxo_patient)
      Project.find_or_create_by(Id: 39) { |p| p.assign_attributes(Name: "Toxo IgG", WithCutter: false, PlateDimensionX: 8, PlateDimensionY: 12, is_blocked_online: false, InjectionVolume: 0, eng_name: "Toxo IgG") }
      Measurement.create!(SampleId: sample.Id, ProjectId: 39, Status: 1, MaterialType: 0, IsRepeat: false)

      stats = described_class.new(user: contractor, window: 30).call
      expect(stats[:authorized_measurements_count]).to eq(0)
    end

    describe "unused_reserved_codes_count" do
      it "counts an institution's unused RSC even when there are zero Samples in the whole table" do
        create(:reserved_sample_code, Code: "ABCDEFG", InstitutionId: institution.id, package_id: nil)

        stats = described_class.new(user: contractor, window: 30).call
        expect(stats[:unused_reserved_codes_count]).to eq(1)
      end

      it "excludes an RSC that is linked to a Sample" do
        rsc = create(:reserved_sample_code, Code: "ABCDEFG", InstitutionId: institution.id, package_id: nil)
        sample = create(:toxo_sample, Code: "TX001A", patient: toxo_patient)
        sample.update_column(:reserved_sample_code_id, rsc.Id)

        stats = described_class.new(user: contractor, window: 30).call
        expect(stats[:unused_reserved_codes_count]).to eq(0)
      end

      it "counts an RSC not linked to any Sample alongside one that is linked" do
        used_rsc = create(:reserved_sample_code, Code: "ABCDEFG", InstitutionId: institution.id, package_id: nil)
        create(:reserved_sample_code, Code: "HIJKLMN", InstitutionId: institution.id, package_id: nil)
        sample = create(:toxo_sample, Code: "TX001A", patient: toxo_patient)
        sample.update_column(:reserved_sample_code_id, used_rsc.Id)

        stats = described_class.new(user: contractor, window: 30).call
        expect(stats[:unused_reserved_codes_count]).to eq(1)
      end

      it "excludes legacy codes that are not 7 characters long" do
        create(:reserved_sample_code, Code: "JV4XJ", InstitutionId: institution.id, package_id: nil)

        stats = described_class.new(user: contractor, window: 30).call
        expect(stats[:unused_reserved_codes_count]).to eq(0)
      end

      it "excludes RSCs belonging to a different institution" do
        other_institution = create(:institution)
        create(:reserved_sample_code, Code: "ABCDEFG", InstitutionId: other_institution.id, package_id: nil)

        stats = described_class.new(user: contractor, window: 30).call
        expect(stats[:unused_reserved_codes_count]).to eq(0)
      end
    end
  end
end
