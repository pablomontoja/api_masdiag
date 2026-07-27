module MasdiagRecurring
  class DailyDelayedSamplesMailer < ApplicationMailer
    default :template_path => "mailers/#{self.name.underscore}"

    def send_mail(samples, project)
      @samples = samples
      @project = project

      mail(subject: "Opóźnienia w wykonaniu analiz", to: @project.responsible_person_email)
    end

  end
end