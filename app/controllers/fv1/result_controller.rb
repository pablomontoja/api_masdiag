class Fv1::ResultController < ApplicationController
  before_action :set_rsc
  before_action :set_sample

  def show
    json_response(ResultResource.call(@sample, @current_rsc))
  end

  private

  def set_rsc
    @current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: sample_code)

    if @current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution." }, :unprocessable_entity)
    end
  end

  def set_sample
    @sample = Sample.find_by(Code: sample_code)

    if @sample.nil?
      json_response({ message: "Unknown sample code." }, :unprocessable_entity)
    end
  end

  def sample_code
    params.require(:code).upcase
  end



end
