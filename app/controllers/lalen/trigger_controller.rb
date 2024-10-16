class Lalen::TriggerController < ApplicationController
  include LalenCheck
  before_action :set_rsc
  before_action :set_sample

  def send_result
    if Current.api_account.result_post_endpoint.blank?
      json_response({message: "current_result_post_endpoint_url is not set, please use POST /v1/setup/set_result_post_endpoint_url to setup your endpoint"}, :unprocessable_entity)
      return
    end

    meas = Measurement.includes(:sample).where(Status: 5).find_by(Samples: { Code: sample_code })

    if meas.nil?
      Sentry.capture_message("#{sample_code} - does not have authorized measurements.")
    else
      Notification::LalenResultSender.perform_later(meas) 
      render json: {message: "result endpoint responded with status 200"}, status: 200      
    end

  end

  private

  def set_rsc
    @current_rsc = ReservedSampleCode.where(InstitutionId: V1::Common::LALEN_INSTITUTION_IDS).find_by(Code: sample_code)

    if @current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution." }, :unprocessable_entity)
    end
  end

  def set_sample
    @sample = Sample.find_by(Code: sample_code)

    if @sample.nil?
      json_response({ message: "Unknown sample code or sample does not exist." }, :unprocessable_entity)
    end
  end

  def sample_code
    params.require(:code).upcase
  end

end
