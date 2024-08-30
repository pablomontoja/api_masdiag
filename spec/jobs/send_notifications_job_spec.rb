require 'rails_helper'

RSpec.describe MasdiagMailer::SendNotificationsJob, type: :job do
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

    before(:each) do
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.deliveries = []
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
    end

    it 'sends notifications for enabled contractors' do
    	expect{ MasdiagMailer::SendNotificationsJob.perform_later }.to have_enqueued_job(MasdiagMailer::SendNotificationsJob)
      perform_enqueued_jobs
      # expect { MasdiagMailer::SendNotificationsJob.perform_now }.to have_been_enqueued(MasdiagMailer::ResultNotificationMailer)#.with(contractor1.Id, [online_file1.id])
      # expect(MasdiagMailer::ResultNotificationMailer).to receive(:send_mail).with(contractor1.Id, [online_file1.id]).and_call_original
      expect { MasdiagMailer::SendNotificationsJob.perform_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'does not send notifications for disabled contractors' do
      expect(MasdiagMailer::ResultNotificationMailer).not_to receive(:send_mail).with(contractor2.Id, anything)
      # expect { MasdiagMailer::SendNotificationsJob.perform_now }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it 'marks files as sent' do
      MasdiagMailer::SendNotificationsJob.perform_now
      expect(online_file1.reload.is_notification_send).to be true
    end

    it 'does not send notifications if there are no files' do
      online_file1.update(is_notification_send: true)
      online_file2.update(is_notification_send: true)
      expect(MasdiagMailer::ResultNotificationMailer).not_to receive(:send_mail)
      expect { MasdiagMailer::SendNotificationsJob.perform_now }.not_to change { ActionMailer::Base.deliveries.count }
    end
  end
end
