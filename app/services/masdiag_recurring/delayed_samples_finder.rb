module MasdiagRecurring
  class DelayedSamplesFinder < ApplicationService

    def initialize
    end

    def call
      begin
        expired = []

        Project.where(id: [2, 3, 6, 7, 10, 11, 12, 14, 15, 16, 17, 18, 20, 21, 22, 23, 24, 25, 26]).each do |project|
          exp_hours = 192
          exp_hours = 72 if project.Id == 2
          exp_hours = 72 if project.Id == 22
          exp_hours = 696 if [14, 16, 17].include?(project.Id)
          exp_hours = 360 if [3, 15, 21, 25].include?(project.Id)
          exp_hours = 240 if project.Id == 18 # Inga chciała żeby Acylokarnityny przychodził wcześniej, po zmianie z 7 na 10 dni roboczych ustawiono 240 godzin, czyli 4 dni przed terminem
          expiration_date = exp_hours.hours.ago

          possible_sample_ids = Measurement.includes(:sample).where(ProjectId: project.Id, Samples: { IsControlSample: false, IsWrongRegistration: false }).where("Status < ?", 5).where(Samples: { AcceptanceDate: 3.months.ago..expiration_date }).pluck(:SampleId)

          samples_authorized_ids = Measurement.where(SampleId: possible_sample_ids, Status: 5, ProjectId: project.Id).pluck(:SampleId)
          expired_ids = possible_sample_ids - samples_authorized_ids
          expired = expired + Measurement.includes(:sample).where(SampleId: expired_ids.uniq, ProjectId: project.Id).group(:SampleId).pluck('ProjectId,Samples.Code,Samples.AcceptanceDate,Samples.RegistrationDate')
        end

        items = []

        items = expired.map do |s|
          { project_id: s[0], code: s[1], acceptance_date: s[2].localtime, registration_date: s[3].localtime }
        end

        handle_result(items)
      rescue StandardError => e
        Sentry.capture_exception(e)
        handle_error(e)
      end
    end

  end
end