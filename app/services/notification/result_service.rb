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
    response = Faraday.post(url, result)
    # byebug
  end
end
