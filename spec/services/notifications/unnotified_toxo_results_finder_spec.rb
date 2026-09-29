require "rails_helper"

RSpec.describe Notifications::UnnotifiedToxoResultsFinder do
  let(:toxo_institution) { create(:institution, name: "Toxo Inst") }

  before { stub_const("V1::Common::TOXO_INSTITUTION_IDS", [toxo_institution.id]) }

  def eligible_toxo_sample
    contractor = create(:contractor, institution: toxo_institution, email: "doc@example.com",
                                     are_notifications_enabled: true)
    patient = create(:patient, contractor: contractor, IsVirtual: false)
    create(:sample, patient: patient)
  end

  def measurement_for(sample, authorized_at: Notifications::ResultAvailableJob::CUTOFF_DATE.in_time_zone + 1.day)
    create(:measurement, sample: sample, project: create(:project_without_fixed_id), AuthorizedAt: authorized_at)
  end

  it "includes an authorized, unnotified Toxo measurement" do
    measurement = measurement_for(eligible_toxo_sample)

    expect(described_class.call).to include(measurement)
  end

  it "excludes a measurement with AuthorizedAt nil" do
    measurement = measurement_for(eligible_toxo_sample, authorized_at: nil)

    expect(described_class.call).not_to include(measurement)
  end

  it "excludes a measurement authorized before CUTOFF_DATE" do
    measurement = measurement_for(eligible_toxo_sample,
                                   authorized_at: Notifications::ResultAvailableJob::CUTOFF_DATE.in_time_zone - 1.day)

    expect(described_class.call).not_to include(measurement)
  end

  it "excludes an already-notified measurement" do
    measurement = measurement_for(eligible_toxo_sample)
    Note.create!(key: "result-available-email", subject: measurement)

    expect(described_class.call).not_to include(measurement)
  end

  it "excludes a measurement belonging to a non-Toxo institution's sample" do
    other_institution = create(:institution, name: "Lab Inst")
    contractor = create(:contractor, institution: other_institution, email: "lab@example.com",
                                     are_notifications_enabled: true)
    patient = create(:patient, contractor: contractor, IsVirtual: false)
    sample = create(:sample, patient: patient)
    measurement = measurement_for(sample)

    expect(described_class.call).not_to include(measurement)
  end

  it "includes a measurement whose sample's patient is virtual but whose ReservedSampleCode institution is Toxo" do
    create(:reserved_sample_code_with_institution, Code: "JV4XJ", institution: toxo_institution)
    sample = create(:not_registered_sample_in_lab, Code: "JV4XJ")
    sample.patient.update_column(:IsVirtual, true) # set_time_stamps callback forces false on save
    measurement = measurement_for(sample)

    expect(described_class.call).to include(measurement)
  end
end
