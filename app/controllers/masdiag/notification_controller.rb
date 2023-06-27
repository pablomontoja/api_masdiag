class Masdiag::NotificationController < ApplicationController
  include MasdiagCheck

  def trigger
    errors = []
    ids = ApiAccount.pluck(:contractor_id)
    meas_ids = OnlineFile.includes(measurement: {sample: :patient}).where(is_notification_send: false).where(Patients: {ContractorId: ids}).pluck(:measurement_id)
    @files_done = Hash.new

    Measurement.where(Id: meas_ids).each do |meas|
      res = Notification::ResultService.call(meas.sample)

      if res.success?
        @files_done[meas.online_file] = res.payload.to_json
      else
        errors << res.error&.join(", ")
      end
    end

    build_res_sending_events()  

    if errors.count.zero?
      render json: {message: "result endpoint responded with status 200"}, status: 200
    else
      render json: { message: errors.join(", ")}, status: 500
    end

  end

  private

  def build_res_sending_events
    return nil if @files_done == nil

    @files_done.each do |file, json|

      f = Fileable.new
      event = f.build_result_sending_event

      event.measurement = file.measurement
      event.sample = file.measurement.sample
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
      # byebug
      tmpfile = Tempfile.new([SecureRandom.uuid,'.json'], Rails.root.join('tmp') )
      tmpfile.binmode
      tmpfile.write(json)
      tmpfile.rewind

      dbfile = f.db_files.build
      dbfile.file_content = tmpfile.read
      dbfile.file_type = "application/json"
      dbfile.file_length = dbfile.file_content.size
      tmpfile.close

      # pdf content
      dbfile = f.db_files.build
      dbfile.file_content = file.file_contents
      dbfile.file_type = "application/pdf"
      dbfile.file_length = dbfile.file_content.size

      f.save

      file.update_attribute(:is_notification_send, true)
      file.update_attribute(:when_patient_notification_send, Time.current)
    end
  end

end
