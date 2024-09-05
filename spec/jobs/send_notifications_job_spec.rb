require 'rails_helper'
# require './app/mailers/masdiag_notificator/result_notification_mailer'

include MasdiagNotificator

RSpec.describe MasdiagNotificator::SendNotificationsJob, type: :job do
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

    # before(:each) do
    #   ActionMailer::Base.delivery_method = :test
    #   ActionMailer::Base.perform_deliveries = true
    #   ActionMailer::Base.deliveries = []
    # end

    # after(:each) do
    #   ActionMailer::Base.deliveries.clear
    # end

    it 'queues the job' do
      expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end

    it 'is in background queue' do
      expect(MasdiagNotificator::SendNotificationsJob.new.queue_name).to eq('background')
    end

    it 'executes perform' do
      # message_delivery = instance_double(ActionMailer::MessageDelivery)
      # expect(MasdiagNotificator::ResultNotificationMailer).to receive(:notify_by_mail)
      # allow(message_delivery).to receive(:deliver_later)

      # perform_enqueued_jobs { job }
      assert_emails 1 do
        MasdiagNotificator::ResultNotificationMailer.notify_by_mail().deliver_alter
      end
    end

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    # it 'sends notifications for enabled contractors' do
    # 	expect{ MasdiagNotificator::SendNotificationsJob.perform_later }.to have_enqueued_job(MasdiagNotificator::SendNotificationsJob)
    #   perform_enqueued_jobs
    #   # expect { MasdiagNotificator::SendNotificationsJob.perform_now }.to have_been_enqueued(MasdiagNotificator::ResultNotificationMailer)#.with(contractor1.Id, [online_file1.id])
    #   # expect(MasdiagNotificator::ResultNotificationMailer).to receive(:send_mail).with(contractor1.Id, [online_file1.id]).and_call_original
    #   expect { MasdiagNotificator::SendNotificationsJob.perform_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
    # end

    # it 'does not send notifications for disabled contractors' do
    #   expect(MasdiagNotificator::ResultNotificationMailer).not_to receive(:send_mail).with(contractor2.Id, anything)
    #   # expect { MasdiagNotificator::SendNotificationsJob.perform_now }.not_to change { ActionMailer::Base.deliveries.count }
    # end

    # it 'marks files as sent' do
    #   MasdiagNotificator::SendNotificationsJob.perform_now
    #   expect(online_file1.reload.is_notification_send).to be true
    # end

    # it 'does not send notifications if there are no files' do
    #   online_file1.update(is_notification_send: true)
    #   online_file2.update(is_notification_send: true)
    #   expect(MasdiagNotificator::ResultNotificationMailer).not_to receive(:send_mail)
    #   expect { MasdiagNotificator::SendNotificationsJob.perform_now }.not_to change { ActionMailer::Base.deliveries.count }
    # end
  end
end
