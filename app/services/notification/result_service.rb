class Notification::ResultService < ApplicationService

  def initialize(sample)
    @sample = sample
  end

  def call
    # byebug
    result = ResultResource.call(@sample, @sample.rsc)
    institution_id = @sample.patient.contractor.institution_id
    api_account = ApiAccount.all.select { |a| a.institution.id == institution_id  }.first
    url = api_account.result_post_endpoint

    return handle_error(["blank result post endpoint url"]) if url.blank?

    begin
      response = Faraday.post(url, result.to_json, {'Content-Type' => 'application/json'})
      handle_result()
    rescue Faraday::Error => e
      return handle_error([e.to_s]) if e.response.nil?
      err = ["status: #{e.response[:status]}", "body: #{e.response[:body]}"]
      handle_error(err)
    end
  end
end
