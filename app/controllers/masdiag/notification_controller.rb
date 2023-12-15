class Masdiag::NotificationController < ApplicationController
  include MasdiagCheck

  # TODO it need to be tested
  def trigger
    errors = []
    ids = ApiAccount.pluck(:contractor_id)
    meas_ids = Measurement.includes(sample: :patient).where(Status: 5).where(Patients: {ContractorId: ids}).pluck(:Id)
    sent_meas_ids = ResultSendingEvent.where(sent_through: 6, measurement_id: meas_ids).pluck(:measurement_id)
    meas_ids = meas_ids - sent_meas_ids
    @meases_done = Hash.new

    Measurement.where(Id: meas_ids).each do |meas|
      res = Notification::ResultService.call(meas.sample)
      if res.success?
        @meases_done[meas] = res.payload.to_json
      else
        errors << res.error&.join(", ")
      end
    end

    build_res_sending_events()  

    if errors.count.zero?
      render json: { message: "result endpoint responded with status 200" }, status: 200
    else
      render json: { message: errors.join(", ")}, status: 500
    end
  end

  # REQUIRED PARAMS: sample_id 
  def sample_status_changed
    sample = Sample.find(params[:sample_id])
    @samples_done = Hash.new

    res = Notification::ResultService.call(sample)
    if res.success?
      @samples_done[sample] = res.payload.to_json
      build_notification_sending_events()
      render json: { message: "result endpoint responded with status 200" }, status: 200
    else
      render json: { message: res.error&.join(", ")}, status: 500
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

        f.save

        meas.online_file.update_attribute(:is_notification_send, true)
        meas.online_file.update_attribute(:when_notification_send, Time.current)
      end
      
    end
  end

end
