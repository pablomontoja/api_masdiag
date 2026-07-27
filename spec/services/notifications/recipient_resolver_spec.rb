require "rails_helper"

RSpec.describe Notifications::RecipientResolver do
  let(:institution) { create(:institution, email_for_notifications: "inst@example.com") }

  describe "registered events (result_available, sample_accepted, sample_rejected, sample_registration_confirmation)" do
    it "returns the contractor email when notifications are enabled" do
      contractor = create(:contractor, institution: institution,
                                       email: "doc@example.com", are_notifications_enabled: true)
      patient = create(:patient, contractor: contractor, IsVirtual: false)
      sample = create(:sample, patient: patient)

      expect(described_class.call(sample: sample, event: :result_available)).to eq("doc@example.com")
    end

    it "returns nil (skip) when notifications are disabled" do
      contractor = create(:contractor, institution: institution,
                                       email: "doc@example.com", are_notifications_enabled: false)
      patient = create(:patient, contractor: contractor, IsVirtual: false)
      sample = create(:sample, patient: patient)

      expect(described_class.call(sample: sample, event: :result_available)).to be_nil
    end
  end

  describe "reminder events (registration_reminder, registration_reminder_final)" do
    it "returns institution.email_for_notifications resolved via code -> RSC, not the virtual patient's contractor" do
      wrong_contractor = create(:contractor, email: "wrong@example.com", are_notifications_enabled: true)
      virtual_patient = create(:patient, contractor: wrong_contractor)
      virtual_patient.update_column(:IsVirtual, true) # callback forces false on save
      sample = create(:sample, Code: "TXCODE", patient: virtual_patient)
      create(:reserved_sample_code, Code: "TXCODE", InstitutionId: institution.id, package_id: nil)

      expect(described_class.call(sample: sample, event: :registration_reminder)).to eq("inst@example.com")
    end

    it "returns nil (skip) when the institution has no notification email" do
      institution.update!(email_for_notifications: nil)
      virtual_patient = create(:patient)
      virtual_patient.update_column(:IsVirtual, true) # callback forces false on save
      sample = create(:sample, Code: "TXCODE", patient: virtual_patient)
      create(:reserved_sample_code, Code: "TXCODE", InstitutionId: institution.id, package_id: nil)

      expect(described_class.call(sample: sample, event: :registration_reminder_final)).to be_nil
    end

    it "ignores the per-event contractor flags (reminders go to the institution)" do
      wrong_contractor = create(:contractor, email: "wrong@example.com",
                                             are_notifications_enabled: true,
                                             allow_result_notifications: false,
                                             allow_sample_acceptance_notifications: false)
      virtual_patient = create(:patient, contractor: wrong_contractor)
      virtual_patient.update_column(:IsVirtual, true)
      sample = create(:sample, Code: "TXCODE", patient: virtual_patient)
      create(:reserved_sample_code, Code: "TXCODE", InstitutionId: institution.id, package_id: nil)

      expect(described_class.call(sample: sample, event: :registration_reminder)).to eq("inst@example.com")
    end
  end

  describe "per-event contractor opt-out flags (global are_notifications_enabled AND event flag)" do
    {
      sample_accepted:    :allow_sample_acceptance_notifications,
      sample_rejected:    :allow_sample_rejection_notifications,
      result_available:   :allow_result_notifications,
      sample_registration_confirmation: :allow_sample_registration_notifications
    }.each do |event, flag|
      context "event #{event} controlled by #{flag}" do
        def sample_for(institution, **contractor_attrs)
          contractor = create(:contractor, institution: institution,
                                            email: "doc@example.com",
                                            are_notifications_enabled: true, **contractor_attrs)
          patient = create(:patient, contractor: contractor, IsVirtual: false)
          create(:sample, patient: patient)
        end

        it "returns the email when the flag is true" do
          sample = sample_for(institution, flag => true)
          expect(described_class.call(sample: sample, event: event)).to eq("doc@example.com")
        end

        it "returns nil (skip) when the flag is false" do
          sample = sample_for(institution, flag => false)
          expect(described_class.call(sample: sample, event: event)).to be_nil
        end

        it "returns nil when global are_notifications_enabled is false regardless of the flag" do
          contractor = create(:contractor, institution: institution, email: "doc@example.com",
                                           are_notifications_enabled: false, flag => true)
          patient = create(:patient, contractor: contractor, IsVirtual: false)
          sample = create(:sample, patient: patient)
          expect(described_class.call(sample: sample, event: event)).to be_nil
        end
      end
    end
  end
end
