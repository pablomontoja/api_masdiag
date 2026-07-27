require 'rails_helper'

RSpec.describe MasdiagMailer::SendAcceptanceNotificationsJob, type: :job do
  describe '#perform' do
    let(:sample) { create(:sample) }
    let(:patient) { create(:patient) }
    let(:contractor) { create(:contractor) }

    before do
      allow(Sample).to receive(:find).and_return(sample)
      allow(sample).to receive(:patient).and_return(patient)
      allow(patient).to receive(:contractor).and_return(contractor)
    end

    context 'when processing valid samples' do
      it 'sends acceptance notification email for valid sample' do
        patient.email = 'test@example.com'
        mailer = double('mailer')
        allow(MasdiagMailer::SendAcceptanceNotificationsMailer).to receive(:send_mail_to_patient).and_return(mailer)
        allow(mailer).to receive(:deliver_later)

        described_class.perform_now([sample.Id])

        expect(MasdiagMailer::SendAcceptanceNotificationsMailer).to have_received(:send_mail_to_patient).with(sample.Id)
      end

      it 'does not send email when patient email is blank' do
        patient.email = ''
        
        expect(MasdiagMailer::SendAcceptanceNotificationsMailer).not_to receive(:send_mail_to_patient)
        
        described_class.perform_now([sample.Id])
      end

      it 'skips samples with api_account contractors' do
        allow(contractor).to receive(:api_account).and_return(true)
        
        expect(MasdiagMailer::SendAcceptanceNotificationsMailer).not_to receive(:send_mail_to_patient)
        
        described_class.perform_now([sample.Id])
      end
    end

    context 'when sample is nil' do
      it 'skips processing for nil samples' do
        allow(Sample).to receive(:find).and_return(nil)
        
        expect(MasdiagMailer::SendAcceptanceNotificationsMailer).not_to receive(:send_mail_to_patient)
        
        described_class.perform_now([1])
      end
    end

    context 'when an error occurs' do
      it 'sends error notification' do
        allow(Sample).to receive(:find).and_raise(StandardError.new('Test error'))
        error_mailer = double('error_mailer', deliver_later: true)
        allow(MasdiagMailer::SendErrorNotificationsMailer).to receive(:send_mail).and_return(error_mailer)

        described_class.perform_now([sample.Id])

        expect(MasdiagMailer::SendErrorNotificationsMailer).to have_received(:send_mail)
          .with(hash_including(SendAcceptanceNotificationsJob: "ERROR: Test error"))
      end
    end

    context 'when processing multiple samples' do
      let(:sample2) { create(:sample, Code: "XXXXX") }
      let(:sample3) { create(:sample, Code: "YYYYY") }

      it 'processes multiple samples correctly' do
        [sample, sample2, sample3].each do |s|
          allow(s).to receive_message_chain(:patient, :email).and_return('test@example.com')
          allow(s).to receive_message_chain(:patient, :contractor, :api_account).and_return(false)
        end

        mailer = double('mailer')
        allow(MasdiagMailer::SendAcceptanceNotificationsMailer).to receive(:send_mail_to_patient).and_return(mailer)
        allow(mailer).to receive(:deliver_later)

        described_class.perform_now([sample.Id, sample2.id, sample3.id])

        expect(MasdiagMailer::SendAcceptanceNotificationsMailer).to have_received(:send_mail_to_patient).exactly(3).times
      end
    end
  end
end