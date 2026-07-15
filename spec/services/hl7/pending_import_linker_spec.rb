require 'rails_helper'

RSpec.describe Hl7::PendingImportLinker do
  let(:system_user) do
    User.find_or_create_by!(Login: "hl7_system") do |u|
      u.FirstName = "HL7"; u.LastName = "System"; u.email = "hl7system@masdiag.pl"
      u.Password = "x"; u.Salt = "x"; u.IsActive = true; u.Role = 0
      u.encrypted_password = "$"; u.sign_in_count = 0; u.HasSmartCard = false
    end
  end

  def project_32
    Project.find_or_create_by(Id: 32) do |p|
      p.Name = "NutriPATH Metals"; p.WithCutter = false
      p.PlateDimensionX = 8; p.PlateDimensionY = 12
      p.InjectionVolume = 0; p.is_blocked_online = false; p.eng_name = "NutriPATH Metals"
    end
  end

  before do
    system_user
    project_32
  end

  describe "#link_pending_imports" do
    it "links awaiting import to matching measurement and enqueues job" do
      sample      = create(:sample, Code: "LINK01")
      measurement = create(:measurement, sample: sample, ProjectId: 32, Status: 1)
      hl7_import  = create(:hl7_import, :awaiting_registration,
                            kit_code_extracted: "LINK01",
                            hl7_test_code: "UCR,usEssEl,UsMetox")

      expect(Hl7::MeasurementImportJob).to receive(:perform_later).with(hl7_import.id)

      result = described_class.new.link_pending_imports

      expect(result[:linked]).to eq(1)
      expect(result[:waiting]).to eq(0)
      expect(result[:errors]).to be_empty

      expect(hl7_import.reload.measurement_id).to eq(measurement.id)
      expect(hl7_import.reload.status).to eq("pending")
    end

    it "leaves import unchanged and increments waiting when sample not found" do
      hl7_import = create(:hl7_import, :awaiting_registration,
                           kit_code_extracted: "NOTFOUND",
                           hl7_test_code: "UCR,usEssEl,UsMetox")

      result = described_class.new.link_pending_imports

      expect(result[:linked]).to eq(0)
      expect(result[:waiting]).to eq(1)
      expect(hl7_import.reload.status).to eq("awaiting_registration")
    end

    it "marks registration_error for unknown test code" do
      hl7_import = create(:hl7_import, :awaiting_registration,
                           kit_code_extracted: "LINK01",
                           hl7_test_code: "UNKNOWN-CODE")

      result = described_class.new.link_pending_imports

      expect(hl7_import.reload.status).to eq("registration_error")
      expect(result[:errors]).not_to be_empty
    end

    it "processes multiple awaiting imports independently" do
      sample      = create(:sample, Code: "MULTI1")
      measurement = create(:measurement, sample: sample, ProjectId: 32, Status: 1)

      imp_linked  = create(:hl7_import, :awaiting_registration,
                            kit_code_extracted: "MULTI1",
                            hl7_test_code: "UCR,usEssEl,UsMetox")
      imp_waiting = create(:hl7_import, :awaiting_registration,
                            kit_code_extracted: "MULTI2NOTFOUND",
                            hl7_test_code: "UCR,usEssEl,UsMetox")

      allow(Hl7::MeasurementImportJob).to receive(:perform_later)

      result = described_class.new.link_pending_imports

      expect(result[:linked]).to eq(1)
      expect(result[:waiting]).to eq(1)
      expect(imp_linked.reload.measurement_id).to eq(measurement.id)
      expect(imp_waiting.reload.status).to eq("awaiting_registration")
    end
  end
end
