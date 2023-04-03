class SendMailNotificationJob < ApplicationJob
  retry_on StandardError, wait: :exponentially_longer, attempts: 10 do |job, error|
    errors = [Time.current.to_s, "MASDIAG API", job.class.name, "Exception - #{error}", "Job details: #{job.to_json}"]
    puts errors
    # IndMailer.after_error(errors).deliver_later
  end
  queue_as :default

  def perform(action, resource)
    MailNotificationService.call(action, resource)
  end

end
