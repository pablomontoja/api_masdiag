module MasdiagMailer
  class ThreeMethylDopaMailer < ApplicationMailer
    include Rails.application.routes.url_helpers
    default :template_path => "mailers/#{self.name.underscore}"

    def after_sample_registration(sample_id)
      @sample = Sample.find(sample_id)
      return if @sample.nil? || @sample.patient&.email.blank?

      attachments["potwierdzenie-rejestracji-próbki-#{@sample.Code}.pdf"] = RegistrationConfirmationThreeOmdPdf.new(sample_id).render

      mail(
         to: @sample.patient.email,
         subject: "Potwierdzenie rejestracji próbki (3-OMD) – #{@sample.Code}"
      )
    end
 
  end
end