class Notification::ResultService < ApplicationService

  def initialize(sample)
    @sample = sample
  end

  def call
    result = ResultResource.call(@sample, @sample.rsc)
    institution_id = @sample.patient.contractor.institution_id
    api_account = ApiAccount.all.select { |a| a.institution.id == institution_id  }.first
    url = api_account.result_post_endpoint

    return handle_error(["blank result post endpoint url"]) if url.blank?

    # pp "============================== Notification::ResultService =============================="
    # pp result
    # pp "============================== Notification::ResultService =============================="

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
      err = ["status: #{e.response[:status]}", "body: #{e.response[:body]}"]
      handle_error(err)
    end
  end
end
