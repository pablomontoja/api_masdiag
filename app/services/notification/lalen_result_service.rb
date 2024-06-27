class Notification::LalenResultService < ApplicationService

  def initialize(sample)
    @sample = sample
  end

  def call    
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
      handle_result(result)
    rescue Faraday::Error => e
      return handle_error([e.to_s]) if e.response.nil?
      err = ["Notification::ResultService - sample: #{@sample.Code} - ERROR - status: #{e.response[:status]}", "body: #{e.response[:body]}"]
      handle_error(err)
    end
  end
end
