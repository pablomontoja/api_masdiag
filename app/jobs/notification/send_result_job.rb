class Notification::SendResultJob < ApplicationJob
  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |job, error|
    Sentry.capture_exception(error)
  end

  def perform(measurement_id)
  	@meases_done = Hash.new

    meas = Measurement.find(measurement_id)
    # lalen_institution_id = meas.sample.rsc&.InstitutionId
    # if V1::Common::LALEN_INSTITUTION_IDS.include?(lalen_institution_id)
    #   return if ResultSendingEvent.where(sent_through: 6, measurement_id: measurement_id).where("address LIKE ?", "%lalen%").any?
    #   Notification::LalenResultSender.perform_later(meas)
    #   return
    # end

    return if ResultSendingEvent.where(sent_through: 6, measurement_id: measurement_id).where.not("address LIKE ?", "%lalen%").any?

    res = Notification::ResultService.call(meas.sample)

    if res.success?
      @meases_done[meas] = res.payload.to_json
      build_res_sending_events() 
    else
      puts res.error&.join(", ")
      raise Notification::JobError.new("Notification::SendResultJob has problems with sending result for meas #{meas&.Id}, sample code: #{meas.sample.Code}")
    end   
  end

private

  def build_res_sending_events
    return nil if @meases_done.empty?

    @meases_done.each do |meas, json|

      f = Fileable.new
      event = f.build_result_sending_event

      event.measurement = meas
      event.sample = meas.sample
      event.sent_date = Time.current
      event.sent_through = 6   # MasdiagAPI
      event.recipient = "MasdiagAPI"
      event.result_text_representation = json
      event.address = "MasdiagAPI /masdiag/notifications/trigger"

                                          # public enum MethodsOfSendingEnum
                                          # {
                                          #     Undefined = 0,
                                          #     EmailNotification,
                                          #     EmailPdf,
                                          #     CerascreenAPI,
                                          #     EmailCsv,
                                          #     GenericAssaysAPI,
                                          #     MasdiagAPI
                                          # }

      # mail content
      tmpfile = Tempfile.new([SecureRandom.uuid,'.json'], Rails.root.join('tmp') )
      tmpfile.binmode
      tmpfile.write(json)
      tmpfile.rewind

      dbfile = f.db_files.build
      dbfile.file_content = tmpfile.read
      dbfile.file_type = "application/json"
      dbfile.file_length = dbfile.file_content.size
      tmpfile.close

      if meas.online_file
        # pdf content
        dbfile = f.db_files.build
        dbfile.file_content = meas.online_file.file_contents
        dbfile.file_type = "application/pdf"
        dbfile.file_length = dbfile.file_content.size        

        meas.online_file.update_attribute(:is_notification_send, true)
        meas.online_file.update_attribute(:when_notification_send, Time.current)
      end

      f.save
      
    end
  end
	
end