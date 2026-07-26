require "rails_helper"

RSpec.describe MasdiagRecurring::OmegaquantCsvResultsGenerator, type: :service do
  let!(:omegaquant_institution) { create(:institution, name: "OmegaQuant Analytics") }
  let(:contractor) { create(:contractor, institution: omegaquant_institution) }
  let(:patient) { create(:patient, contractor: contractor) }
  let(:project) { create(:project) }
  let(:analyte) { create(:analyte, project: project, NameInAPI: "vitamin_d", Unit: "ng/ml") }

  let!(:reserved_code) do
    create(:reserved_sample_code, Code: "OQ1", InstitutionId: omegaquant_institution.id, package: create(:package))
  end
  let!(:sample) { create(:sample, Code: "OQ1", patient: patient, IsControlSample: false) }
  let!(:measurement) { create(:measurement, sample: sample, project: project, Status: 5) }
  let!(:result) { create(:result, MeasurementId: measurement.Id) }
  let!(:analyte_result) { create(:analyte_result, ResultId: result.MeasurementId, AnalyteId: analyte.Id, Value: 42.5) }

  subject(:outcome) { described_class.call([measurement.Id]) }

  def csv_rows(payload)
    payload.split("\n").map { |line| line.split("\t") }
  end

  it "succeeds and returns a CSV with the sample code and analyte columns" do
    expect(outcome.success?).to eq(true)
    rows = csv_rows(outcome.payload[:csv])
    expect(rows.first).to eq(["Sample code", "vitamin_d [ng/ml]"])
    expect(rows.second).to eq(["OQ1", "42.5"])
  end

  it "returns the settled measurement ids for idempotency notes" do
    expect(outcome.payload[:measurement_ids]).to eq([measurement.Id])
  end

  context "when the sample is a control sample" do
    before { sample.update_column(:IsControlSample, true) }

    it "excludes it from the report" do
      rows = csv_rows(outcome.payload[:csv])
      expect(rows.map(&:first)).not_to include("OQ1")
    end
  end

  context "when the measurement is not authorized (Status != 5)" do
    before { measurement.update_column(:Status, 1) }

    it "excludes it from the report" do
      rows = csv_rows(outcome.payload[:csv])
      expect(rows.map(&:first)).not_to include("OQ1")
    end
  end
end
