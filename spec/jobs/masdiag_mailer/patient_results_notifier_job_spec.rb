require 'rails_helper'
include MasdiagMailer

RSpec.describe PatientResultsNotifierJob, type: :job do
  let(:patient) { create(:patient, send_results_on_mail: true, email: "test@example.com") }
  let(:contractor) { create(:contractor, api_account: nil) }
  let(:api_account) { create(:api_account, contractor: contractor) }
  let(:sample) { create(:sample, patient: patient) }
  let(:measurement) { create(:measurement, sample: sample, AuthorizedAt: 3.months.ago) }
  let(:online_file) { create(:online_file, measurement: measurement, is_patient_notification_send: false) }

  before do
    patient.update(contractor: contractor)
  end

  describe '#perform' do
    context 'when eligible files exist' do
      before do
        allow_any_instance_of(described_class).to receive(:eligible_files_exist?).and_return(true)
      end

      it 'processes eligible files' do
        allow_any_instance_of(described_class).to receive(:eligible_files).and_return([[online_file.measurement_id, patient.id]])
        expect_any_instance_of(described_class).to receive(:process_eligible_files)

        described_class.perform_now
      end
    end

    context 'when no eligible files exist' do
      before do
        allow_any_instance_of(described_class).to receive(:eligible_files_exist?).and_return(false)
      end

      it 'does not process eligible files' do
        expect_any_instance_of(described_class).not_to receive(:process_eligible_files)
        
        described_class.perform_now
      end
    end
  end

  describe '#eligible_files_exist?' do
    it 'returns true if there are eligible files' do
      allow_any_instance_of(described_class).to receive(:eligible_files).and_return([[online_file.measurement_id, patient.id]])
      expect(subject.send(:eligible_files_exist?)).to be_truthy
    end

    it 'returns false if there are no eligible files' do
      allow_any_instance_of(described_class).to receive(:eligible_files).and_return([])
      expect(subject.send(:eligible_files_exist?)).to be_falsy
    end
  end

  describe '#process_eligible_files' do
    before do
      allow_any_instance_of(described_class).to receive(:eligible_files).and_return([[online_file.measurement_id, patient.id]])
    end

    context 'when conditions to send notification are met' do
      it 'calls the mailer to send email' do
        expect(PatientResultNotificationMailer).to receive(:send_mail).with(patient.id, online_file.measurement_id).and_return(double(deliver_later: true))

        subject.send(:process_eligible_files)
      end
    end

    context 'when conditions to send notification are not met' do
      before do
        patient.update(email: nil)  # Change the email to make the condition false
      end

      it 'does not call the mailer' do
        expect(PatientResultNotificationMailer).not_to receive(:send_mail)

        subject.send(:process_eligible_files)
      end
    end
  end

  describe '#should_send_notification?' do
    it 'returns true if all conditions are met' do
      expect(subject.send(:should_send_notification?, patient)).to be_truthy
    end

    it 'returns false if the patient email is blank' do
      patient.update(email: nil)
      expect(subject.send(:should_send_notification?, patient)).to be_falsy
    end

    it 'returns false if the patient does not want to receive results via email' do
      patient.update_columns(send_results_on_mail: false)
      expect(subject.send(:should_send_notification?, patient)).to be_falsy
    end

    it 'returns false if the patient is associated with an API account' do
      contractor.update(api_account: api_account)
      expect(subject.send(:should_send_notification?, patient)).to be_falsy
    end

    it 'returns false if the patient is linked to a hospital contractor' do
      institution = create(:institution, kind: 'Hospital')
      contractor.update(institution: institution)
      expect(subject.send(:should_send_notification?, patient)).to be_falsy
    end
  end
end