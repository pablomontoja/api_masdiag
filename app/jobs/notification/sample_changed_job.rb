class Notification::SampleChangedJob < ApplicationJob
  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, error|
    errors = [Time.current.to_s, "MASDIAG API", job.class.name, "Exception - #{error}", "Job details: #{job.to_json}"]
    puts errors
    # IndMailer.after_error(errors).deliver_later
  end
  queue_as :default

	def perform(sample_id)
		@sample = Sample.find(sample_id)
    @samples_done = Hash.new

    res = Notification::ResultService.call(@sample)

    Thread.new do
      res = Notification::LalenResultService.call(@sample)
      puts res.error&.join(", ") unless res.success?
    end

    if res.success?
      @samples_done[@sample] = res.payload.to_json
      build_notification_sending_events()
    else
      puts res.error&.join(", ")
      raise Notification::JobError.new("Notification::SampleChangedJob has problems with sending result for sample #{@sample&.Code}")
    end
	end

private

  def build_notification_sending_events
    return nil if @samples_done == nil

    @samples_done.each do |sample, json|
      f = Fileable.new
      event = f.build_result_sending_event

      event.measurement = nil
      event.sample = sample
      event.sent_date = Time.current
      event.sent_through = 6   # MasdiagAPI
      event.recipient = "MasdiagAPI"
      event.result_text_representation = json
      event.address = "MasdiagAPI /masdiag/notifications/sample_status_changed"

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

      f.save
    end    
  end

	
end