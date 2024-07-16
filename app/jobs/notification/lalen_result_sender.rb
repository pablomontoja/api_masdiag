class Notification::LalenResultSender < ApplicationJob

  def perform(sample)
    @sample = sample
    @meases_done = Hash.new

    institution_id = @sample.rsc.InstitutionId
    return unless V1::Common::LALEN_INSTITUTION_IDS.include?(institution_id)

    result = ResultResource.call(@sample, @sample.rsc)
    api_account = ApiAccount.find_by(username: "lalenAU")
    url = api_account.result_post_endpoint

    return handle_error(["#{@sample&.Code} - blank result post endpoint url"]) if url.blank?

    begin
      conn = Faraday.new() do |f|
        f.response :raise_error # raise Faraday::Error on status code 4xx or 5xx
        f.request :json
        f.request :authorization, :basic, api_account.result_post_endpoint_credentials.username, api_account.result_post_endpoint_credentials.password if api_account.result_post_endpoint_credentials
        f.response :json
      end
      
      response = conn.post(url, result.to_json)

      @meases_done[@sample] = result.to_json
      build_res_sending_events() 

    rescue Faraday::Error => e
      return handle_error([e.to_s]) if e.response.nil?
      err = ["Notification::ResultService - sample: #{@sample.Code} - ERROR - status: #{e.response[:status]}", "body: #{e.response[:body]}"]
      handle_error(err)
    end
  end

private

  def handle_error(err)
    pp err
  end

  def build_res_sending_events
    return nil if @meases_done.empty?

    @meases_done.each do |sample, json|

      f = Fileable.new
      event = f.build_result_sending_event

      event.measurement = nil
      event.sample = sample
      event.sent_date = Time.current
      event.sent_through = 6   # MasdiagAPI
      event.recipient = "MasdiagAPI"
      event.result_text_representation = json
      event.address = "MasdiagAPI --> LALEN MasdiagComAPI"

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
