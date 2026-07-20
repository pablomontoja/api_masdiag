require "rails_helper"

RSpec.describe Notifications::TemplateResolver do
  before do
    stub_const("V1::Common::TOXO_INSTITUTION_IDS", [toxo_institution.id])
  end

  let(:toxo_institution) { create(:institution, name: "Toxo Inst") }
  let(:lab_institution)  { create(:institution, name: "Lab Inst") }

  describe ".institution_for / .family_for (registered sample)" do
    it "resolves via the patient's contractor and returns :toxo for a toxo institution" do
      contractor = create(:contractor, institution: toxo_institution)
      patient = create(:patient, contractor: contractor, IsVirtual: false)
      sample = create(:sample, patient: patient)

      expect(described_class.institution_for(sample)).to eq(toxo_institution)
      expect(described_class.family_for(sample)).to eq(:toxo)
    end

    it "returns :lab for a non-toxo institution" do
      contractor = create(:contractor, institution: lab_institution)
      patient = create(:patient, contractor: contractor, IsVirtual: false)
      sample = create(:sample, patient: patient)

      expect(described_class.family_for(sample)).to eq(:lab)
    end
  end

  describe ".institution_for (unregistered sample — virtual patient)" do
    it "resolves the institution via code -> reserved sample code, NOT the virtual patient's contractor" do
      # Virtual patient belongs to a contractor in the LAB institution...
      wrong_contractor = create(:contractor, institution: lab_institution)
      virtual_patient = create(:patient, contractor: wrong_contractor)
      virtual_patient.update_column(:IsVirtual, true) # callback forces false on save
      sample = create(:sample, Code: "TXCODE", patient: virtual_patient)
      # ...but the code's reserved sample code belongs to the TOXO institution.
      create(:reserved_sample_code, Code: "TXCODE", InstitutionId: toxo_institution.id, package_id: nil)

      expect(described_class.institution_for(sample)).to eq(toxo_institution)
      expect(described_class.family_for(sample)).to eq(:toxo)
    end
  end
end
