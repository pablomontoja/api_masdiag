class V1::ResultController < ApplicationController

  def show
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

    res = []
    # byebug
    current_rsc.projects.each do |pr|
      meas = sample.measurements.order(Status: :desc).find_by(ProjectId: pr.Id)
      if meas&.online_file&.file_contents.present?
        meas.online_file.prepare_active_storage
        res << {test: meas.project.Name, status: get_status(meas.Status), unencrypted_result: url_for(meas.online_file.unencrypted_result) }
        next
      end
      res << {test: meas.project.Name, status: get_status(meas.Status), unencrypted_result: nil}
    end

    # "http://127.0.0.1:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBDdz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--2f19a40975b3e71377c6ae91d492cb06dcd3693f/JXHXW_2.pdf"

    json_response({results: res})
  end

  private

  def sample_code
    params.require(:code).upcase
  end

  def get_status(int)
    case int
    when 1
      return "in laboratory"
    when 2
      return "in measurement"
    when 3
      return "in measurement"
    when 4
      return "measured"
    when 5
      return "authorized"
    when 6
      return "cancelled measurement"
    when 7
      return "registered online"
    else
      return "unknown"
    end
  end

end


# {
#   "results": [
#     {
#       "test": "Witamina D",
#       "status": "authorized",
#       "unencrypted_result": "http://127.0.0.1:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCdz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--a03618e791b03f185ab659eeddd512108d545761/R5XGB_2.pdf"
#     },
#     {
#       "test": "Przeciwciała anty-SARS-CoV-2",
#       "status": "authorized",
#       "unencrypted_result": "http://127.0.0.1:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBDQT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--4d2021383dea13ac9a90c37b98cad8cabed6dbd9/R5XGB_9.pdf"
#     },
#     {
#       "test": "Aminokwasy",
#       "status": "authorized",
#       "unencrypted_result": "http://127.0.0.1:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBDUT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--71b864ec386634b7339618aa68990de0c04b9b21/R5XGB_3.pdf"
#     }
#   ]
# }
