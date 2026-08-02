module MasdiagRecurring

  class MonthlyPtcSummaryMailer < ApplicationMailer
    require 'csv'
    default :template_path => "mailers/#{self.name.underscore}"
    after_action :add_notes

    def monthly_mail(ptc_meas_ids, rest_meas_ids) # ptc_meas_ids and rest_meas_ids should be an Array of measurement ids
      @headers = [" ","Sample_code", "Sample_registration_date", "Sample_arrival_date", "Result_delivered_date", "Physician_title", "Physician_name", "Physician_surname", "Physician_email", "Organisation_name", "Organisation_address", "3OMD_result", "Flag", "L-DOPA_supplementation", "Supplemented_product", "Hypotonia", "Delayed_psychomotor_development", "ANS_symptoms", "Motor_dysfunction", "Behavioural_disorders", "CNS_imaging_changes", "Diurnal_symptoms_variability"]

      ptc_summary_samples = []
      @ptc_measurements = Measurement.includes(sample: {patient: :contractor}).includes(:project, sample: { answers: :option }).where(Id: ptc_meas_ids).order("Contractors.institution_id ASC").all

      @ptc_measurements.map do |m|
        ptc_summary_samples << [
                            m.sample.Code,
                            m.sample.RegistrationDate&.strftime("%F"),
                            m.sample.AcceptanceDate&.strftime("%F"),
                            m.AuthorizedAt&.strftime("%F"),
                            m.sample.answers.find_by(survey_question_id: 19)&.other_field_text,
                            m.sample.answers.find_by(survey_question_id: 20)&.other_field_text,
                            m.sample.answers.find_by(survey_question_id: 21)&.other_field_text,
                            m.sample.patient.email,
                            m.sample.answers.find_by(survey_question_id: 23)&.other_field_text,
                            m.sample.answers.find_by(survey_question_id: 24)&.other_field_text,
                            AnalyteResult.find_by(ResultId: m.Id, AnalyteId: 324)&.Value,
                            " ",
                            get_multiple_answers(m.sample.answers.where(survey_question_id: 25)),
                            get_multiple_answers(m.sample.answers.where(survey_question_id: 26)),
                            get_multiple_answers(m.sample.answers.where(survey_question_id: 27)),
                            get_multiple_answers(m.sample.answers.where(survey_question_id: 28)),
                            get_multiple_answers(m.sample.answers.where(survey_question_id: 29)),
                            get_multiple_answers(m.sample.answers.where(survey_question_id: 30)),
                            get_multiple_answers(m.sample.answers.where(survey_question_id: 31)),
                            get_multiple_answers(m.sample.answers.where(survey_question_id: 32)),
                            get_multiple_answers(m.sample.answers.where(survey_question_id: 33))
                          ]
      end

      ptc_csv_file_path = "tmp/#{SecureRandom.uuid}.csv"

      CSV.open(ptc_csv_file_path, 'w:Windows-1250', col_sep: ";") do |csv|      
        csv << @headers.map { |field| field.encode('Windows-1250') }

        ptc_summary_samples.each_with_index do |smp, idx|
          csv << ["#{idx+1}"] + smp
        end
      end


      rest_summary_samples = []
      @rest_measurements = Measurement.includes(sample: {patient: :contractor}).includes(:project, sample: { answers: :option }).where(Id: rest_meas_ids).order("Contractors.institution_id ASC").all

      @rest_measurements.map do |m|
        rest_summary_samples << [
                            m.sample.Code,
                            m.sample.RegistrationDate&.strftime("%F"),
                            m.sample.AcceptanceDate&.strftime("%F"),
                            m.AuthorizedAt&.strftime("%F"),                          
                            " ",
                            m.sample.Comment,
                            " ",
                            m.sample.patient.email,
                            m.sample.patient.contractor.institution.name,
                            m.sample.patient.contractor.institution.address,
                            AnalyteResult.find_by(ResultId: m.Id, AnalyteId: 324)&.Value,
                            " ",
                            " ",
                            " ",
                            " ",
                            " ",
                            " ",
                            " ",
                            " ",
                            " ",
                            " "
                          ]
      end

      rest_csv_file_path = "tmp/#{SecureRandom.uuid}.csv"

      CSV.open(rest_csv_file_path, 'w:Windows-1250', col_sep: ";") do |csv|      
        csv << @headers.map { |field| field.encode('Windows-1250') }

        rest_summary_samples.each_with_index do |smp, idx|
          csv << ["#{idx+1}"] + smp
        end
      end

      attachments["ptc-#{Date.today.to_s(:db)}.csv"] = File.read(ptc_csv_file_path)
      attachments["rest-#{Date.today.to_s(:db)}.csv"] = File.read(rest_csv_file_path)

      mail(to: ['anna.grabowska@masdiag.pl','pawel.swider@masdiag.pl'], subject: 'Zestawienie próbek 3-OMD wykonanych w poprzednim miesiącu')
    end

  private

    def get_multiple_answers(answers)
      res = answers.map do |a|
        a.option.is_other_option == true ? a.other_field_text : a.option.option_text
      end
      res.join(", ")
    end

    def add_notes()
      @ptc_measurements.each do |meas|
        Note.create!(key: "included-in-monthly-ptc-report", subject: meas, description: "Zestawienie próbek 3-OMD wykonanych w poprzednim miesiącu, plik CSV z dnia #{Time.now.strftime("%F")}")
      end

      @rest_measurements.each do |meas|
        Note.create!(key: "included-in-monthly-ptc-report", subject: meas, description: "Zestawienie próbek 3-OMD wykonanych w poprzednim miesiącu, plik CSV z dnia #{Time.now.strftime("%F")}")
      end
    end

  end
end


  # "Sample_code",
  # "Sample_registration_date",
  # "Sample_arrival_date",
  # "Result_delivered_date",
  # "Physician_title",
  # "Physician_name",
  # "Physician_surname",
  # "Physician_email",
  # "Organisation_name",
  # "Organisation_address",
  # "3OMD_result",
  # "Flag",
  # "L-DOPA_supplementation",
  # "Supplemented_product",
  # "Hypotonia",
  # "Delayed_psychomotor_development",
  # "ANS_symptoms",
  # "Motor_dysfunction",
  # "Behavioural_disorders",
  # "CNS_imaging_changes",
  # "Diurnal_symptoms_variability"
