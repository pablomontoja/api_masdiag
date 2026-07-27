module MasdiagRecurring
  class MonthlyHospitalSummaryMailer < ApplicationMailer
    require 'csv'
    default :template_path => "mailers/#{self.name.underscore}"
    after_action :add_notes
    SummarySample = Struct.new(:code, :test, :patient, :accept_date, :auth_date, :comment, :contractor, :institution)

    def monthly_mail(meas_ids) # meas_ids should be an Array of measurement ids
      summary_samples = []
      @measurements = Measurement.includes(sample: {patient: :contractor}).includes(:project).where(Id: meas_ids).order("Contractors.institution_id ASC").all
      @measurements.map do |m|
        summary_samples << SummarySample.new( m.sample.Code, m.project.Name, m.sample.patient.fullname, m.sample.AcceptanceDate, m.AuthorizedAt, m.sample.Comment, m.sample.patient.contractor.fullname, m.sample.patient.contractor.institution.name)
      end

      csv_file_path = "tmp/#{SecureRandom.uuid}.csv"
      gen_csv_file(summary_samples, csv_file_path)

      attachments["szpitale-#{Date.today}.csv"] = File.read(csv_file_path)

      mail(to: ['anna.grabowska@masdiag.pl', 'pawel.swider@masdiag.pl'], subject: 'Zestawienie próbek wykonanych w poprzednim miesiącu dla Szpitali')
    end

  private

    def gen_csv_file(summary_samples, csv_file_path)
      CSV.open(csv_file_path, 'w:Windows-1250', col_sep: ";") do |csv|
        header = ["LP", "Kod próbki", "Nazwa analizy", "Pacjent", "Data przyjęcia", "Data wydania wyniku", "Osoba kierująca", "Oddział/Poradnia", "Instytucja"]
        
        csv << header.map { |field| field.encode('Windows-1250') }
        summary_samples.each_with_index do |smp, idx|
          csv << ["#{idx+1}", "#{smp.code}", "#{smp.test}", "#{smp.patient}", "#{smp.accept_date.strftime("%F")}", "#{smp.auth_date.strftime("%F")}", "#{smp.comment}", "#{smp.contractor}", "#{smp.institution}"]
        end

      end
    end


    def add_notes()
      @measurements.each do |meas|
        Note.create!(key: "included-in-monthly-hospital-report", subject: meas, description: "Zestawienie wykonań dla szpitali, plik CSV z dnia #{Time.now.strftime("%F")}")
      end
    end

  end
end