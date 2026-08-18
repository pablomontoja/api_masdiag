require 'rails_helper'

RSpec.describe Hl7::MeasurementImporter do
  def metals_hl7
    File.read(Rails.root.join("spec/metals.hl7"))
  end

  def iodine_hl7
    File.read(Rails.root.join("spec/iodine.hl7"))
  end

  def build_import(hl7_content, measurement, test_code: "UCR,usEssEl,UsMetox")
    import = create(:hl7_import, :with_measurement,
                    measurement: measurement,
                    hl7_test_code: test_code,
                    status: :pending)
    import.hl7_file.attach(
      io: StringIO.new(hl7_content),
      filename: "test.hl7",
      content_type: "text/plain"
    )
    import
  end

  def project_32
    Project.find_or_create_by(Id: 32) do |p|
      p.Name = "NutriPATH Metals"; p.WithCutter = false
      p.PlateDimensionX = 8; p.PlateDimensionY = 12
      p.InjectionVolume = 0; p.is_blocked_online = false; p.eng_name = "NutriPATH Metals"
    end
  end

  def project_29
    Project.find_or_create_by(Id: 29) do |p|
      p.Name = "NutriPATH Iodine"; p.WithCutter = false
      p.PlateDimensionX = 8; p.PlateDimensionY = 12
      p.InjectionVolume = 0; p.is_blocked_online = false; p.eng_name = "NutriPATH Iodine"
    end
  end

  def make_analyte(name_in_api, project_id, unit: "µg/l")
    Analyte.find_or_create_by(NameInAPI: name_in_api, ProjectId: project_id) do |a|
      a.Name = name_in_api; a.IsCalculatedFromOthers = false; a.is_required = true
      a.ExcludedFromStatistic = false; a.material_type = 0; a.Unit = unit
    end
  end

  let(:system_user) do
    User.find_or_create_by!(Login: "hl7_system") do |u|
      u.FirstName = "HL7"; u.LastName = "System"; u.email = "hl7system@masdiag.pl"
      u.Password = "x"; u.Salt = "x"; u.IsActive = true; u.Role = 0
      u.encrypted_password = "$"; u.sign_in_count = 0; u.HasSmartCard = false
    end
  end

  let(:instrument) do
    ActiveRecord::Base.with_connection do |conn|
      conn.execute(
        "INSERT IGNORE INTO instruments (id, name, short_name) VALUES (15, 'NutriPATH', 'NP')"
      )
    end
    Struct.new(:id).new(15)
  end

  before do
    system_user
    instrument
    stub_const("Hl7::Config::SYSTEM_USER_ID", system_user.Id)
    stub_const("Hl7::Config::INSTRUMENT_ID", 15)
  end

  describe "#import — Project 32 (urine metals)" do
    # metals.hl7: kit A6Y1IF, creatinine 11.4 mmol/L, chromium 0.14 ug/gCR, zinc 0.21 mg/gCR
    let(:sample)      { create(:sample, Code: "A6Y1IF") }
    let(:measurement) { create(:measurement, sample: sample, ProjectId: 32, Status: 1) }
    let(:krea_analyte)      { make_analyte("krea", 32, unit: "mg/dl") }
    let(:chromium_analyte)  { make_analyte("chromium", 32, unit: "µg/l") }
    let(:chromium_crea)     { make_analyte("chromium_crea", 32, unit: "µg/g crea") }
    let(:zinc_analyte)      { make_analyte("zinc", 32, unit: "µg/l") }
    let(:zinc_crea)         { make_analyte("zinc_crea", 32, unit: "µg/g crea") }

    before do
      project_32
      krea_analyte; chromium_analyte; chromium_crea; zinc_analyte; zinc_crea
    end

    it "marks the import as completed and sets Measurement.Status = 4" do
      import = build_import(metals_hl7, measurement)
      result = described_class.new(import).import
      expect(result).to be true
      expect(import.reload.status).to eq("completed")
      expect(measurement.reload.Status).to eq(4)
    end

    it "creates AnalyteResult rows with correct chromium values" do
      import = build_import(metals_hl7, measurement)
      described_class.new(import).import

      db_result = Result.find_by(MeasurementId: measurement.Id)
      expect(db_result).to be_present

      # creatinine: 11.4 mmol/L → g/L = 11.4 × 113.12 / 1000 = 1.28957
      # chromium raw: 0.14 × 1.28957 = 0.18054 µg/L
      chromium_row = AnalyteResult.find_by(ResultId: measurement.Id, AnalyteId: chromium_analyte.id)
      expect(chromium_row).to be_present
      expect(chromium_row.Value.to_f).to be_within(0.0001).of(0.14 * (11.4 * 113.12 / 1000.0))

      # chromium_crea: stored as-is = 0.14
      crea_row = AnalyteResult.find_by(ResultId: measurement.Id, AnalyteId: chromium_crea.id)
      expect(crea_row).to be_present
      expect(crea_row.Value.to_f).to be_within(0.0001).of(0.14)
    end

    it "applies ×1000 factor for mg/gCR analytes (Zinc)" do
      import = build_import(metals_hl7, measurement)
      described_class.new(import).import

      zinc_row = AnalyteResult.find_by(ResultId: measurement.Id, AnalyteId: zinc_analyte.id)
      expect(zinc_row).to be_present
      # zinc raw: 0.21 × 1000 × 1.28957 = 270.81 µg/L
      expected = 0.21 * 1000.0 * (11.4 * 113.12 / 1000.0)
      expect(zinc_row.Value.to_f).to be_within(0.01).of(expected)

      # zinc_crea: 0.21 mg/gCR → ×1000 → 210 µg/gCR (was broken: stored 0.21)
      zinc_crea_row = AnalyteResult.find_by(ResultId: measurement.Id, AnalyteId: zinc_crea.id)
      expect(zinc_crea_row).to be_present
      expect(zinc_crea_row.Value.to_f).to be_within(0.01).of(210.0)
    end

    it "marks import as failed and returns false when creatinine is missing" do
      no_crea_hl7 = <<~HL7.strip
        MSH|^~\\&|NUTRIPATH|NUTRIPATH|MAS|MAS|20240115120000||ORU^R01|MSG003|P|2.3.1
        PID|1||12345||A6Y1IF^^^^^^^||19800101|M
        OBR|1||ORD001|UCR,usEssEl,UsMetox^UCR,usEssEl,UsMetox^0001|||20240115||||||A6Y1IF
        OBX|1|NM|42220-4^Chromium^LN||0.14|ug/gCR||||F
      HL7
      import = build_import(no_crea_hl7, measurement)
      result = described_class.new(import).import
      expect(result).to be false
      expect(import.reload.status).to eq("failed")
    end

    it "marks import as failed when MSH segment is missing" do
      bad_hl7 = "OBR|1||ORD001|test"
      import = build_import(bad_hl7, measurement)
      result = described_class.new(import).import
      expect(result).to be false
      expect(import.reload.status).to eq("failed")
    end

    it "records warnings for unmapped OBX codes" do
      import = build_import(metals_hl7, measurement)
      importer = described_class.new(import)
      importer.import
      # metals.hl7 contains many unmapped codes (Iron, Calcium, Magnesium, etc.)
      expect(importer.warnings).not_to be_empty
      expect(importer.stats[:analytes_skipped]).to be > 0
    end

    it "counts FT comment segments (metals.hl7 has 2 FT segments)" do
      import = build_import(metals_hl7, measurement)
      importer = described_class.new(import)
      importer.import
      expect(importer.stats[:comments_skipped]).to eq(2)
    end

    it "replaces existing AnalyteResult rows on re-import without accumulating duplicates" do
      import = build_import(metals_hl7, measurement)
      described_class.new(import).import
      first_count = AnalyteResult.where(ResultId: measurement.Id).count

      import.update!(status: :pending)
      import.hl7_file.attach(io: StringIO.new(metals_hl7), filename: "test.hl7", content_type: "text/plain")

      described_class.new(import).import

      expect(AnalyteResult.where(ResultId: measurement.Id).count).to eq(first_count)
    end

    it "stays completed even if archiving fails" do
      allow(Aws::S3::Client).to receive(:new).and_raise(StandardError, "archive error")
      import = build_import(metals_hl7, measurement)
      result = described_class.new(import).import
      expect(result).to be true
      expect(import.reload.status).to eq("completed")
    end
  end

  describe "#import — Project 29 (urine iodine)" do
    # iodine.hl7: kit 2LI3FN (from PID), creatinine usCr=5.4 mmol/L,
    #             uIodEx=121.9 ug/gCR, UR-IODINE=74 ug/L, 1 FT comment
    let(:sample)      { create(:sample, Code: "2LI3FN") }
    let(:measurement) { create(:measurement, sample: sample, ProjectId: 29, Status: 1) }
    let(:kreatinin_analyte) { make_analyte("kreatinin_iu", 29, unit: "mg/dl") }
    let(:jod_krea_analyte)  { make_analyte("jod_krea_iu", 29, unit: "ug/g creatinine") }
    let(:iodine_analyte)    { make_analyte("iodine_ng_ml", 29, unit: "ng/ml") }

    before do
      project_29
      kreatinin_analyte; jod_krea_analyte; iodine_analyte
    end

    it "stores creatinine as mg/dl (mmol/L → mg/dl conversion)" do
      import = build_import(iodine_hl7, measurement, test_code: "UR-IODINE,uIodEx,UIodCom,usCr")
      described_class.new(import).import

      krea_row = AnalyteResult.find_by(ResultId: measurement.Id, AnalyteId: kreatinin_analyte.id)
      expect(krea_row).to be_present
      # 5.4 mmol/L × 113.12 / 10 = 61.0848 mg/dl
      expected_mg_dl = 5.4 * 113.12 / 10.0
      expect(krea_row.Value.to_f).to be_within(0.001).of(expected_mg_dl)
    end

    it "stores iodine normalized (ug/gCR) directly as-is" do
      import = build_import(iodine_hl7, measurement, test_code: "UR-IODINE,uIodEx,UIodCom,usCr")
      described_class.new(import).import

      jod_row = AnalyteResult.find_by(ResultId: measurement.Id, AnalyteId: jod_krea_analyte.id)
      expect(jod_row).to be_present
      expect(jod_row.Value.to_f).to be_within(0.001).of(121.9)
    end

    it "stores iodine absolute (ug/L) as ng/ml (1:1)" do
      import = build_import(iodine_hl7, measurement, test_code: "UR-IODINE,uIodEx,UIodCom,usCr")
      described_class.new(import).import

      iodine_row = AnalyteResult.find_by(ResultId: measurement.Id, AnalyteId: iodine_analyte.id)
      expect(iodine_row).to be_present
      expect(iodine_row.Value.to_f).to be_within(0.001).of(74.0)
    end

    it "skips FT (formatted text) segments" do
      import = build_import(iodine_hl7, measurement, test_code: "UR-IODINE,uIodEx,UIodCom,usCr")
      importer = described_class.new(import)
      importer.import
      expect(importer.stats[:comments_skipped]).to eq(1)
    end
  end
end
