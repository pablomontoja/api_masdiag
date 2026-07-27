module MasdiagRecurring
  class MonthlyForeignSamplesReportMailer < ApplicationMailer
    default :template_path => "mailers/#{self.name.underscore}"

    def monthly_mail
      @measurement_summaries = MeasurementSummary.includes(:institution).where(institution: { kind: "ForeignInstitution" }).last_month

      return if @measurement_summaries.size.zero?

      mail(to: ['anna.kolodynska@masdiag.pl','webadmin@masdiag.pl', 'anna.grabowska@masdiag.pl', 'renata.halak@masdiag.pl', 'tomasz.bienkowski@masdiag.pl', 'dariusz.kolodynski@masdiag.pl', 'lalen.dogan@masdiag.pl'], subject: 'Zestawienie wykonanych próbek dostarczonych z zagranicy')
    end

  end
end