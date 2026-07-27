require "rails_helper"

RSpec.describe Notifications::RegistrationRemindersFinder do
  let(:toxo_institution) { create(:institution) }

  before { stub_const("V1::Common::TOXO_INSTITUTION_IDS", [toxo_institution.id]) }

  # Builds a delivered sample (AcceptanceDate set) with a virtual patient,
  # whose Code belongs to the toxo institution via a reserved sample code.
  def delivered_unregistered_sample(code:, accepted_days_business_ago:)
    accepted_on = accepted_days_business_ago.business_days.before(Date.current)
    patient = create(:patient)
    patient.update_column(:IsVirtual, true) # callback forces false on save
    sample = create(:sample, Code: code, patient: patient)
    sample.update_column(:AcceptanceDate, accepted_on)
    create(:reserved_sample_code, Code: code, InstitutionId: toxo_institution.id, package_id: nil)
    sample
  end

  it "includes a delivered, unregistered toxo sample past 7 business days" do
    sample = delivered_unregistered_sample(code: "TXOLD1", accepted_days_business_ago: 8)
    expect(described_class.call.map(&:Id)).to include(sample.Id)
  end

  it "excludes a sample only 6 business days past acceptance" do
    delivered_unregistered_sample(code: "TXNEW1", accepted_days_business_ago: 6)
    expect(described_class.call).to be_empty
  end

  it "excludes a registered (non-virtual) sample" do
    patient = create(:patient) # stays non-virtual (callback)
    sample = create(:sample, Code: "TXREG1", patient: patient)
    sample.update_column(:AcceptanceDate, 10.business_days.before(Date.current))
    create(:reserved_sample_code, Code: "TXREG1", InstitutionId: toxo_institution.id, package_id: nil)
    expect(described_class.call).to be_empty
  end

  it "excludes a sample already reminded (final Note exists)" do
    sample = delivered_unregistered_sample(code: "TXDONE", accepted_days_business_ago: 9)
    Note.create!(key: "registration-reminder-final-email", subject: sample)
    expect(described_class.call.map(&:Id)).not_to include(sample.Id)
  end

  it "excludes a sample whose code belongs to a non-toxo institution" do
    other_inst = create(:institution)
    patient = create(:patient)
    patient.update_column(:IsVirtual, true)
    sample = create(:sample, Code: "LABX01", patient: patient)
    sample.update_column(:AcceptanceDate, 10.business_days.before(Date.current))
    create(:reserved_sample_code, Code: "LABX01", InstitutionId: other_inst.id, package_id: nil)
    expect(described_class.call).to be_empty
  end
end
