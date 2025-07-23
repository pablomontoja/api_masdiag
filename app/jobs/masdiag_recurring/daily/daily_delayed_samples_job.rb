class DailyDelayedSamplesJob
  include Delayed::RecurringJob
  run_every 1.day
  run_at '05:50am'

  def perform
    result = DelayedSamplesFinder.call()
    if result.success?
      items = result.payload
      Project.where.not(responsible_person_email: nil).each do |project|
        current_project_items = items.select {|s| s.fetch(:project_id) == project.Id}
        next if current_project_items.length == 0
        DelayedSamplesMailer.send_mail(current_project_items, project).deliver_later
      end
    else
      SendErrorNotificationsMailer.send_mail({DailyDelayedSamplesJob: "ERROR: #{result.error}"})
    end 
  end
end


