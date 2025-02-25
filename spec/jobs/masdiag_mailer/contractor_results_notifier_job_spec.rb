require 'rails_helper'

include MasdiagMailer

RSpec.describe ContractorResultsNotifierJob, type: :job do
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper
  subject(:job) { described_class.perform_later() }

  describe '#perform' do
    let!(:contractor1) { create(:contractor, are_notifications_enabled: true) }
    let!(:contractor2) { create(:contractor, are_notifications_enabled: false) }
    let!(:patient1) { create(:patient, contractor: contractor1) }
    let!(:patient2) { create(:patient, contractor: contractor2) }
    let!(:sample1) { create(:sample, patient: patient1) }
    let!(:sample2) { create(:sample, Code: "ABCDE", patient: patient2) }
    let!(:measurement1) { create(:measurement, sample: sample1) }
    let!(:measurement2) { create(:measurement, sample: sample2, project: nil, ProjectId: 2) }
    let!(:online_file1) { create(:online_file, measurement: measurement1, is_notification_send: false) }
    let!(:online_file2) { create(:online_file, measurement: measurement2, is_notification_send: false) }

    it 'queues the job' do
      expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end

    it 'is in background queue' do
      expect(ContractorResultsNotifierJob.new.queue_name).to eq('background')
    end

    it 'sends notifications for enabled contractors' do	    
	    allow(MasdiagMailer::ContractorResultNotificationMailer).to receive(:send_mail).with(contractor1.Id, [online_file1.measurement_id]).and_call_original
	    expect(MasdiagMailer::ContractorResultNotificationMailer).to receive(:send_mail).with(contractor1.Id, [online_file1.measurement_id])
	    perform_enqueued_jobs { job }
    end

    it 'does not send notifications for disabled contractors' do
    	allow(MasdiagMailer::ContractorResultNotificationMailer).to receive(:send_mail).and_call_original
      expect(MasdiagMailer::ContractorResultNotificationMailer).not_to receive(:send_mail).with(contractor2.Id, [online_file2.measurement_id])
      perform_enqueued_jobs { job }
    end

    it 'send notifications if there are files' do			
			# contractor2.update(are_notifications_enabled: true) # if you uncomment deliveries.count should be 2
      online_file1.update(is_notification_send: false)
      online_file2.update(is_notification_send: false)

      allow(MasdiagMailer::ContractorResultNotificationMailer).to receive(:send_mail).and_call_original
      expect(MasdiagMailer::ContractorResultNotificationMailer).to receive(:send_mail)
      perform_enqueued_jobs { job }
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

		it 'does not send notifications if there are no files' do
      online_file1.update(is_notification_send: true)
      online_file2.update(is_notification_send: true)

      allow(MasdiagMailer::ContractorResultNotificationMailer).to receive(:send_mail).and_call_original
      expect(MasdiagMailer::ContractorResultNotificationMailer).not_to receive(:send_mail)
      perform_enqueued_jobs { job }
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

  end
end
