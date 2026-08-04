class V1::ResultController < ApplicationController

  def show
    current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: sample_code)
    sample = Sample.find_by(Code: sample_code)

    if current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution." }, :unprocessable_content)
      return
    end

    if sample.nil?
      json_response({ message: "Unknown sample code or sample does not exist." }, :unprocessable_content)
      return
    end

    json_response(ResultResource.call(sample, current_rsc))
  end

  private

  def sample_code
    params.require(:code).upcase
  end



end
