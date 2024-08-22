class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  
  layout "mailer"
  default from:     "powiadomienia@masdiag.pl",
          reply_to: "pomoc@masdiag.pl"

  def email_image_tag(image, **options)
    attachments[image] = File.read(Rails.root.join("app/assets/images/#{image}"))
    image_tag attachments[image].url, **options
  end
end
