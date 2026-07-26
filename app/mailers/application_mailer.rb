class ApplicationMailer < ActionMailer::Base
  self.delivery_job = MasdiagMailDeliveryJob
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  default from: "powiadomienia@masdiag.pl", reply_to: "pomoc@masdiag.pl"
  layout "mailer"

  helper_method :email_image_tag
  helper_method :b2b_online_file_url
  
  before_action :wait_three_seconds

  def email_image_tag(image, **options)
    attachments[image] = File.read(Rails.root.join("app/assets/images/#{image}"))
    image_tag attachments[image].url, **options
  end

  def b2b_online_file_url(meas_id)
    "https://partnerzy.masdiag.pl/online_files/#{meas_id}"
  end

private

  def wait_three_seconds
    sleep(3) if Rails.env.production?
  end

end
