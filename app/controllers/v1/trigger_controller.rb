class V1::TriggerController < ApplicationController

  def send_result
    current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: sample_code)
    sample = Sample.find_by(Code: sample_code)

    if current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution." }, :unprocessable_entity)
      return
    end

    if sample.nil?
      json_response({ message: "Unknown sample code." }, :unprocessable_entity)
      return
    end

    res = Notification::ResultService.call(sample)
    # json_response(ResultResource.call(sample, current_rsc))
    if res.success?
      render json: {message: "result sent to endpoint"}, status: 200
    else
      render json: { message: res.error.join(", ")}, status: 500
    end

  end

  private

  def sample_code
    params.require(:code).upcase
  end

end
