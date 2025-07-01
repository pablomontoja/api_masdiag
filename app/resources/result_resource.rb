class ResultResource < ApplicationService
  include Rails.application.routes.url_helpers

  # Status constants for better maintainability
  SAMPLE_STATUS_CANCELLED = 4
  MEASUREMENT_STATUS_AUTHORIZED = 5
  SOAKING_DEGREE_INSUFFICIENT = 4
  SOAKING_DEGREE_WET = 5

  def initialize(sample, current_rsc)
    @sample = sample
    @current_rsc = current_rsc
  end

  def call
    { results: build_results }
  end

  private

  def build_results
    return [build_cancelled_sample_result] if sample_cancelled?
    
    build_measurement_results
  end

  def sample_cancelled?
    @sample.SampleStatus == SAMPLE_STATUS_CANCELLED
  end

  def build_cancelled_sample_result
    {
      sample_code: @sample.Code,
      sample_status: format_sample_status(@sample),
      lab_arrival_time: @sample.AcceptanceDate,
      rejection_reason: rejection_reason(@sample)
    }
  end

  def build_measurement_results
    results = []
    
    @current_rsc&.projects&.each do |project|
      measurement = find_measurement_for_project(project)
      next if measurement.nil?

      results << build_measurement_result(measurement)
    end
    
    results
  end

  def find_measurement_for_project(project)
    # First try to find authorized measurement
    measurement = @sample.measurements
                         .where(Status: MEASUREMENT_STATUS_AUTHORIZED, ProjectId: project.Id)
                         .first
    
    # Fall back to latest measurement by status if none authorized
    measurement || @sample.measurements
                          .where(ProjectId: project.Id)
                          .order(Status: :desc)
                          .first
  end

  def build_measurement_result(measurement)
    base_result = {
      sample_code: measurement.sample.Code,
      test: measurement.project.eng_name,
      authorized_at: measurement.AuthorizedAt,
      lab_arrival_time: measurement.sample.AcceptanceDate,
      measurement_status: measurement_status(measurement.Status),
      sample_status: format_sample_status(measurement.sample),
      unencrypted_result: unencrypted_result_url(measurement),
      raw_result: raw_result_for_measurement(measurement)
    }

    # add_rejection_reason_if_needed(base_result, measurement.sample)
    base_result
  end

  def unencrypted_result_url(measurement)
    return nil unless measurement&.online_file&.file_contents&.present?
    
    measurement.online_file.prepare_active_storage
    url_for(measurement.online_file.unencrypted_result)
  end

  def raw_result_for_measurement(measurement)
    return [] unless measurement.Status == MEASUREMENT_STATUS_AUTHORIZED
    
    RawResultResource.call(measurement)
  end

  def add_rejection_reason_if_needed(result_hash, sample)
    return unless sample.SampleStatus == SAMPLE_STATUS_CANCELLED
    
    result_hash[:rejection_reason] = rejection_reason(sample)
  end

  def rejection_reason(sample)
    case sample.soaking_degree_id
    when SOAKING_DEGREE_INSUFFICIENT
      "quantity not sufficient"
    when SOAKING_DEGREE_WET
      "wet test card"
    else
      ""
    end
  end

  def format_sample_status(sample)
    return sample_status(sample.SampleStatus) if sample.SampleStatus == SAMPLE_STATUS_CANCELLED
    
    "#{sample_state(sample.SampleState)}, #{sample_status(sample.SampleStatus)}"
  end

  # Status mapping methods with improved readability
  def measurement_status(status_code)
    status_mappings = {
      1 => "before measurement",
      2 => "in measurement",
      3 => "in measurement",
      4 => "measured",
      5 => "authorized",
      6 => "cancelled measurement",
      7 => "registered online"
    }
    
    status_mappings.fetch(status_code, "unknown")
  end

  def sample_state(state_code)
    state_mappings = {
      0 => "undefined",
      1 => "out of lab",
      2 => "in lab",
      3 => "sent back",
      4 => "archived",
      5 => "utilized"
    }
    
    state_mappings.fetch(state_code, "unknown")
  end

  def sample_status(status_code)
    status_mappings = {
      0 => "undefined",
      1 => "registered online",
      2 => "accepted for measurement",
      3 => "clarification needed",
      4 => "cancelled",
      5 => "pool recharged after cancellation"
    }
    
    status_mappings.fetch(status_code, "unknown")
  end
end