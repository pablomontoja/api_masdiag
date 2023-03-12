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

    results = []

    if sample.SampleStatus == 4
      h = {sample_code: sample.Code, sample_status: get_status(sample)}
      h[:rejection_reason] = rejection_reason(sample) if sample.SampleStatus == 4
      results << h
    else
      current_rsc.projects.each do |pr|
        meas = sample.measurements.order(Status: :desc).find_by(ProjectId: pr.Id)

        if meas&.online_file&.file_contents.present?
          meas.online_file.prepare_active_storage
          results << {sample_code: meas.sample.Code, test: meas.project.Name, measurement_status: measurement_status(meas.Status), sample_status: get_status(meas.sample), unencrypted_result: url_for(meas.online_file.unencrypted_result) }
          next
        end

        h = {sample_code: meas.sample.Code, test: meas.project.Name, measurement_status: measurement_status(meas.Status), sample_status: get_status(meas.sample), unencrypted_result: nil}
        h[:rejection_reason] = rejection_reason(meas.sample) if meas.sample.SampleStatus == 4
        results << h
      end
    end



    # "http://127.0.0.1:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBDdz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--2f19a40975b3e71377c6ae91d492cb06dcd3693f/JXHXW_2.pdf"

    json_response({results: results})
  end

  private

  def sample_code
    params.require(:code).upcase
  end

  def rejection_reason(sample)
    reason = ""
    reason = "quantity not sufficient" if sample.soaking_degree_id == 4
    reason = "wet test card" if sample.soaking_degree_id == 5
    reason
  end

  def get_status(sample)
    res = ""
    res = "#{sample_state(sample.SampleState)}, #{sample_status(sample.SampleStatus)}" if sample.SampleStatus != 4
    res = "#{sample_status(sample.SampleStatus)}" if sample.SampleStatus == 4
    res
  end

  def measurement_status(int)
    case int
    when 1
      return "before measurement"
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

  def sample_state(int)
    case int
    when 0
      return "undefined"
    when 1
      return "out of lab"
    when 2
      return "in lab"
    when 3
      return "sent back"
    when 4
      return "archived"
    when 5
      return "utilized"
    else
      return "unknown"
    end
  end

  def sample_status(int)
    case int
    when 0
      return "undefined"
    when 1
      return "registered online"
    when 2
      return "accepted for measurement"
    when 3
      return "clarification needed"
    when 4
      return "cancelled"
    when 5
      return "pool recharged after cancellation"
    else
      return "unknown"
    end
  end

end


# public enum SampleState
# {
#     [Description("Niezdefiniowany")]
#     Undefined = 0,
#     [Description("Poza laboratorium")]
#     Outside,
#     [Description("W laboratorium")]
#     InLab,
#     [Description("Odesłana")]
#     SentBack,
#     [Description("Zarchiwizowana")]
#     Archived,
#     [Description("Zutylizowana")]
#     Utilized
# }

# public enum SampleStatus
# {
#     [Description("Niezdefiniowany")]
#     Undefined = 0,
#     [Description("Zarejestrowana Online")]
#     RegisteredOnline,
#     [Description("Zaakceptowana do wycięcia")]
#     AcceptedForCutting,
#     [Description("Do wyjaśnienia")]
#     ClarificationNeeded,
#     [Description("Anulowana")]
#     Canceled,
#     [Description("Przywrócono testy do puli po anulowaniu")]
#     PoolRechargedAfterCancellation
# }

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
