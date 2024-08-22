module MasdiagMailer
  class ResultNotificationForPatientMailer < ApplicationMailer
    default :template_path => "mailers/#{self.class.name.underscore}"
    after_action :set_sendmail

    def send_mail(patient_id, file_ids)
      @show_info_about_leaflet = true
      @patient = Patient.find(patient_id)
      delivery_mail = "powiadomienia@masdiag.pl"

      return nil if @patient.email.blank? || !@patient.send_results_on_mail
      return nil if @patient.contractor&.institution&.kind == "Hospital" && @patient.contractor&.institution_id != 69

      @files = OnlineFile.where(measurement_id: file_ids)

      return nil if @files.count == 0

      @projects = []

      # measurement_id: 1098270, filename: "46XSR_2.pdf", patient_id: 160498, 9681
      # measurement_id: 1097925, filename: "J9IPJ_2.pdf", patient_id: 119026, 1557
      # measurement_id: 1096484, filename: "LDG7B.pdf", patient_id: 160211, 5740

      @files.each do |file|
        tempfile = Tempfile.new([file.filename,'.pdf'], Rails.root.join('tmp') )
        tempfile.binmode
        tempfile.write(file.encrypted_file_contents) if file.encrypted_file_contents != nil
        tempfile.write(file.file_contents) if file.encrypted_file_contents == nil || file.encrypted_file_contents&.size == 0
        tempfile.close

        my_pdf = Origami::PDF.read(tempfile.path, lazy: true, password: patient_password )

        if my_pdf.encrypted?
          attachments[file.filename] = File.read(tempfile.path)
        else
          my_pdf = Origami::PDF.read(tempfile.path)
          tempfile2 = Tempfile.new([SecureRandom.hex(10),'.pdf'], Rails.root.join('tmp') )
          my_pdf.encrypt(user_passwd: patient_password)
          my_pdf.save(tempfile2.path)
          attachments[file.filename] = File.read(tempfile2.path)
        end

        @projects.push(file.measurement.ProjectId)
      end

      if Rails.env.production?
        deliver_with(@patient.contractor.institution.smtp_settings_name) unless @patient.contractor.institution.smtp_settings_name.nil?
        delivery_mail = @patient.contractor.institution.smtp_email unless @patient.contractor.institution.smtp_settings_name.nil? && @patient.contractor.institution.smtp_email.nil?
      end

      if @patient.contractor.institution.patient_email_template_body.blank?
        if @patient.contractor.institution.email_attachment_pdf.blank?
          attach_proper_leaflet(@projects)
        else
          @show_info_about_leaflet = false
        end

        @mail = mail(to: @patient.email, from: delivery_mail, subject: 'Laboratorium Masdiag - powiadomienie')
      else
        attachments['ulotka.pdf'] = @patient.contractor.institution.email_attachment_pdf if @patient.contractor.institution.email_attachment_pdf != nil && @patient.contractor.institution.id != 31
        attach_proper_leaflet(@projects)
        template = ERB.new(@patient.contractor.institution.patient_email_template_body)
        body = template.result(binding)
        @mail = mail(to: @patient.email, from: delivery_mail, subject: 'Laboratorium Masdiag - powiadomienie') do |format|
          format.html { render html: body.html_safe }
        end
      end

      # @mail = mail(to: @patient.email, subject: 'Laboratorium Masdiag - powiadomienie')
    end

    private

    def patient_password
      result = @patient.BirthDate.year.to_s
      result = @patient.Pesel[-4,4] if !@patient.is_foreigner && !@patient.Pesel.blank?
      return result
    end

    def set_sendmail
      return nil if @files == nil

      @files.each do |file|

        f = Fileable.new
        event = f.build_result_sending_event

        event.measurement = file.measurement
        event.sample = file.measurement.sample
        event.sent_date = Time.current
        event.sent_through = 2   # EmailPdf
        event.recipient = "Pacjent"
        event.address = @patient.email

        # mail content
        # byebug
        tmpfile = Tempfile.new([SecureRandom.uuid,'.html'], Rails.root.join('tmp') )
        tmpfile.binmode
        tmpfile.write(@mail.body.decoded)
        tmpfile.rewind

        dbfile = f.db_files.build
        dbfile.file_content = tmpfile.read
        dbfile.file_type = "text/html"
        dbfile.file_length = dbfile.file_content.size
        tmpfile.close

        # pdf content
        dbfile = f.db_files.build
        dbfile.file_content = file.file_contents
        dbfile.file_type = "application/pdf"
        dbfile.file_length = dbfile.file_content.size

        f.save

        file.update_attribute(:is_patient_notification_send, true)
        file.update_attribute(:when_patient_notification_send, Time.current)
      end
    end

    def attach_proper_leaflet(projects)
      pdffile = File.join(Rails.root, 'app', 'pdfs', 'ulotka.pdf')
      pdffileAA = File.join(Rails.root, 'app', 'pdfs', 'ulotka-AA.pdf')
      poradnictwo = File.join(Rails.root, 'app', 'pdfs', 'Poradnictwo metaboliczne.pdf')

      projects.uniq.each do |pro|
        case pro
        when 15
          attachments['Poradnictwo metaboliczne.pdf'] = File.read(poradnictwo)
          suplement = File.join(Rails.root, 'app', 'pdfs', 'profil-kwasow-suplement-do-wyniku.pdf')
          attachments['Profil kwasów organicznych - suplement.pdf'] = File.read(suplement)
        when 16
          attachments['Poradnictwo metaboliczne.pdf'] = File.read(poradnictwo)
        when 17
          attachments['Poradnictwo metaboliczne.pdf'] = File.read(poradnictwo)
        else
          @show_info_about_leaflet = false
        end
      end
    end

  end
end
