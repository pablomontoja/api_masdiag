require "rails_helper"

RSpec.describe MasdiagRecurring::FftbReportGenerator, type: :service do
  let!(:fftb_institution) { create(:institution, id: 83) }
  let(:contractor) { create(:contractor, institution_id: fftb_institution.id) }
  let(:patient) { create(:patient, contractor: contractor, email: "patient@example.com") }
  let(:project) { create(:project) }

  subject(:result) { described_class.call }

  def csv_rows(payload)
    payload.split("\n").map { |line| line.split("\t", -1) }
  end

  it "succeeds and returns a CSV string with the 11-column header" do
    expect(result.success?).to eq(true)
    header = csv_rows(result.payload).first
    expect(header).to eq([
      "Sample Code", "Test", "Email (if blank it means not registered)",
      "Registration Date", "Lab Arrival Date", "Authorized At",
      "Expiration date", "Comment", "Comment 2", "Tests assigned", "Measurements"
    ])
  end

  context "QNS sample" do
    let!(:reserved_code) do
      create(:reserved_sample_code, Code: "FFTB1", InstitutionId: 83, expiry_date: 1.year.from_now, package: create(:package))
    end
    let!(:reserved_test) { create(:reserved_test, reserved_sample_code: reserved_code, project: project) }
    let!(:qns_soaking_degree) { create(:soaking_degree, id: 4) }
    let!(:sample) do
      create(:sample_with_soaking, Code: "FFTB1", patient: patient, soaking_degree: qns_soaking_degree)
    end

    it "lists the sample in the QNS section with its reserved tests and expiry" do
      row = csv_rows(result.payload).find { |r| r[0] == "FFTB1" }
      expect(row[1]).to eq(project.eng_name)
      expect(row[2]).to eq("patient@example.com")
      expect(row[7]).to eq("QNS")
    end
  end

  context "authorized measurement" do
    let!(:reserved_code) do
      create(:reserved_sample_code, Code: "FFTB2", InstitutionId: 83, expiry_date: 1.year.from_now, package: create(:package))
    end
    let!(:reserved_test) { create(:reserved_test, reserved_sample_code: reserved_code, project: project) }
    let!(:sample) { create(:sample, Code: "FFTB2", patient: patient) }
    let!(:measurement) do
      create(:measurement, sample: sample, project: project, AuthorizedAt: Time.current)
    end

    it "lists the measurement row with authorized date and measured/reserved counts" do
      row = csv_rows(result.payload).find { |r| r[0] == "FFTB2" && r[5] != "" }
      expect(row[1]).to eq(project.eng_name)
      expect(row[9]).to eq("1") # reserved_tests_count
      expect(row[10]).to eq("1") # measured count
    end
  end

  context "unregistered generic kit" do
    let!(:generic_patient) { create(:patient, Id: 4798, contractor: contractor) }
    let!(:reserved_code) do
      create(:reserved_sample_code, Code: "FFTB3", InstitutionId: 83, comment: "Generic Kits batch", expiry_date: 1.year.from_now, package: create(:package))
    end
    let!(:sample) { create(:sample, Code: "FFTB3", patient: generic_patient, PatientId: 4798) }

    it "lists the sample as a not registered generic kit" do
      row = csv_rows(result.payload).find { |r| r[0] == "FFTB3" }
      expect(row[7]).to eq("NOT REGISTERED GENERIC KIT")
    end
  end

  context "unused/expired code" do
    let!(:reserved_code) do
      create(:reserved_sample_code, Code: "FFTB4", InstitutionId: 83, expiry_date: 1.day.ago, package: create(:package))
    end

    it "lists the code as an unused kit" do
      row = csv_rows(result.payload).find { |r| r[0] == "FFTB4" }
      expect(row[7]).to eq("UNUSED KIT")
    end
  end

  context "material handler exclusion" do
    let!(:excluded_code) do
      create(:reserved_sample_code, Code: "FFTB5", InstitutionId: 83, material_handler: :dbs_n2, expiry_date: 1.year.from_now, package: create(:package))
    end
    let!(:sample) { create(:sample, Code: "FFTB5", patient: patient) }
    let!(:measurement) do
      create(:measurement, sample: sample, project: project, AuthorizedAt: Time.current)
    end

    it "excludes dbs_n2/dbs_n4 codes from the authorized measurements section (reserved-codes filter)" do
      row = csv_rows(result.payload).find { |r| r[0] == "FFTB5" }
      expect(row).to be_nil
    end
  end
end
