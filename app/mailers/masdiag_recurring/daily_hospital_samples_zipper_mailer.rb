module MasdiagRecurring
  class DailyHospitalSamplesZipperMailer < ApplicationMailer
    require 'csv'
    default :template_path => "mailers/#{self.name.underscore}"
    after_action :add_notes
    PdfFile = Struct.new(:sample_code, :filename, :file_contents)

    def send_mail(meas_ids, institution_id, add_notes: true) # meas_ids should be an Array of measurement ids
      @add_notes = add_notes
      @pdf_files = []
      @institution = Institution.where(kind: "Hospital").find(institution_id)
      @zip_file_path = "tmp/#{SecureRandom.uuid}.zip"
      @recipients = ['magdalena.pajdowska@masdiag.pl', 'renata.halak@masdiag.pl', 'dariusz.kozlowski@masdiag.pl']
      @online_files = OnlineFile.includes(measurement: { sample: {patient: :contractor}})
                                .where(measurement_id: meas_ids)
      @online_files.map do |of|
        patient = of.measurement.sample.patient
        fname = "#{patient.LastName}_#{of.filename}"
        @pdf_files << PdfFile.new(
          of.measurement.sample.Code,
          fname,
          of.file_contents
        )
      end

      return if @online_files.reject(&:blank?).blank?
      
      write_pdfs()

      attachments["Zestawienie #{ get_initials(@institution.name) } #{ 1.day.ago.strftime("%F") } #{ SecureRandom.alphanumeric(3) }.zip"] = File.read(@zip_file_path)

      mail(to: @recipients, subject: "Zestawienie próbek wykonanych w poprzednim dniu dla #{reduce_string(@institution.name)}")
    end

  private

    def write_pdfs
      enc = Zip::TraditionalEncrypter.new('Masdiag')
      buffer = Zip::OutputStream.write_buffer(::StringIO.new(''), enc) do |output|
        @pdf_files.each do |pdf|
          output.put_next_entry(pdf.filename)
          output.write pdf.file_contents        
        end
      end

      buffer.rewind
      File.binwrite(@zip_file_path, buffer.read)
    end

    def add_notes()
      return unless @add_notes
      @online_files.map { |of| of.measurement }.each do |meas|
        Note.create!(key: "included-in-daily-hospital-zip-archive", subject: meas, description: "Archiwum ZIP z analizami dla #{@institution.name}. Plik ZIP z dnia #{Time.now.strftime("%F")}. Adresaci maila: #{@recipients.join(", ")}")
      end
    end

    def get_initials(string)
      reduce_string(string).split(" ").map { |word| word[0].upcase }.join
    end

    def reduce_string(str)
      str.gsub(/[^a-zA-Z0-9\s]/, '').strip
    end

  end
end