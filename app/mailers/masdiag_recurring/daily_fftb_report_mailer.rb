module MasdiagRecurring
  class DailyFftbReportMailer < ApplicationMailer
    require 'csv'
    default :template_path => "mailers/#{self.name.underscore}"

    def send_mail()
      codes = ReservedSampleCode.where(InstitutionId: 83).pluck(:Code)
      generic_codes = ReservedSampleCode.where(InstitutionId: 83).where("comment LIKE ?", "%Generic Kits%").pluck(:Code)

      header = "Sample Code\tTest\tEmail (if blank it means not registered)\tRegistration Date\tLab Arrival Date\tAuthorized At\tComment\n"

      io = StringIO.new("fftb")
      io << header

      result = Sample.where(soaking_degree_id: [4, 5]).includes(:patient).where(Code: codes).pluck("Code", "Patients.email", "RegistrationDate", "AcceptanceDate", "soaking_degree_id").to_a.map{|r| "#{r[0]}\t#{get_reserved_tests(r[0])}\t#{r[1]}\t#{r[2]&.strftime("%Y-%m-%d")}\t#{r[3]&.strftime("%Y-%m-%d")}\t \tQNS\n" }

      result = result + Measurement.includes(sample: :patient).includes(:project).where(Samples: {Code: codes}).pluck("Samples.Code", "Projects.eng_name", "Patients.email", :AuthorizedAt, "Samples.RegistrationDate", "Samples.AcceptanceDate", "Samples.soaking_degree_id").to_a.map{|r| "#{r[0]}\t#{r[1]}\t#{r[2]}\t#{r[4]&.strftime("%Y-%m-%d")}\t#{r[5]&.strftime("%Y-%m-%d")}\t#{r[3]&.strftime("%Y-%m-%d")}\t \n" }

      result = result + Sample.where(PatientId: 4798).includes(:patient).where(Code: generic_codes).pluck("Code", "Patients.email", "RegistrationDate", "AcceptanceDate", "soaking_degree_id").to_a.map{|r| "#{r[0]}\t#{get_reserved_tests(r[0])}\t#{r[1]}\t#{r[2]&.strftime("%Y-%m-%d")}\t#{r[3]&.strftime("%Y-%m-%d")}\t \tNOT REGISTERED GENERIC KIT\n" }

      result.each do |res|
        io << res
      end

      io.rewind

      # file_path = "tmp/FFTB-#{Date.today.strftime("%Y-%m-%d")}.csv"

      # File.open(file_path, 'w') do |f|
      #   f.puts(io.read)
      # end
     
      attachments["masdiag-report-fftb-#{Date.today}.csv"] = io.read

      mail(to: ["tests@foodforthebrain.org", "dariusz.kolodynski@masdiag.pl"], reply_to: "pawel.swider@masdiag.pl", subject: 'FFTB Samples Report')
    end


    private
      
      def get_reserved_tests(code)
        rsc = ReservedSampleCode.find_by(Code: code)
        rsc.projects_eng_names.join(", ")
      end

  end
end