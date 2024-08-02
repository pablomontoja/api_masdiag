class V1::TriggerController < ApplicationController

  def send_result
    if Current.api_account.result_post_endpoint.blank?
      json_response({message: "current_result_post_endpoint_url is not set, please use POST /v1/setup/set_result_post_endpoint_url to setup your endpoint"}, :unprocessable_entity)
      return
    end

    current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: sample_code)
    sample = Sample.find_by(Code: sample_code)

    if current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution." }, :unprocessable_entity)
      return
    end

    if sample.nil?
      json_response({ message: "Unknown sample code or sample does not exist." }, :unprocessable_entity)
      return
    end

    res = Notification::ResultService.call(sample)

    if res.success?
      render json: {message: "result endpoint responded with status 200"}, status: 200
    else
      render json: { message: res.error.join(", ")}, status: 500
    end

  end

  private

  def sample_code
    params.require(:code).upcase
  end

end
