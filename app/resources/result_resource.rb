class ResultResource < ApplicationService
  include Rails.application.routes.url_helpers

  def initialize(sample, current_rsc)
    @sample = sample
    @current_rsc = current_rsc
    @hash = prepare_json
  end

  def call
    @hash
  end

  def prepare_json
    results = []

    if @sample.SampleStatus == 4
      h = {sample_code: @sample.Code, sample_status: get_status(@sample), lab_arrival_time: @sample.AcceptanceDate }
      h[:rejection_reason] = rejection_reason(@sample) if @sample.SampleStatus == 4
      results << h
    else
      @current_rsc&.projects&.each do |pr|
        meas = @sample.measurements.order(Status: :desc).find_by(ProjectId: pr.Id)

        next if meas.nil?

        if meas&.online_file&.file_contents.present?
          meas.online_file.prepare_active_storage
          results << { sample_code: meas.sample.Code, test: meas.project.eng_name, lab_arrival_time: meas.sample.AcceptanceDate, measurement_status: measurement_status(meas.Status), sample_status: get_status(meas.sample), unencrypted_result: url_for(meas.online_file.unencrypted_result), raw_result: RawResultResource.call(meas) }
          next
        end

        h = { sample_code: meas.sample.Code, test: meas.project.eng_name, lab_arrival_time: meas.sample.AcceptanceDate, measurement_status: measurement_status(meas.Status), sample_status: get_status(meas.sample), unencrypted_result: nil }
        h[:rejection_reason] = rejection_reason(meas.sample) if meas.sample.SampleStatus == 4
        results << h
      end
    end

    {results: results}
  end


  private

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
