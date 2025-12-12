class SendMailNotificationDeliveryJob < ApplicationJob
  queue_as :default

  def perform(mailer_class, method_name, delivery_method, args = {})
    # Stub job for testing purposes
    # In a real implementation, this would deliver the mail
  end
end
