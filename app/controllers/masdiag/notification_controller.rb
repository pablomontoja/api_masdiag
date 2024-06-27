class Masdiag::NotificationController < ApplicationController
  include MasdiagCheck

  # NO REQUIRED PARAMS
  # TODO - trigger - it need to be tested
  def trigger
    begin
      errors = []
      ids = ApiAccount.pluck(:contractor_id)
      meas_ids = Measurement.includes(sample: :patient).where(Status: 5).where(Patients: {ContractorId: ids}).pluck(:Id)
      sent_meas_ids = ResultSendingEvent.where(sent_through: 6, measurement_id: meas_ids).pluck(:measurement_id)
      meas_ids = meas_ids - sent_meas_ids
      @meases_done = Hash.new

      Measurement.where(Id: meas_ids).each do |meas|
        Notification::SendResultJob.perform_later(meas.Id)
      end

      render json: { message: "result notifications was properly scheduled" }, status: 200
    rescue StandardError => ex
      pp ex
      render json: { message: "there are problems with scheduling notification jobs"}, status: 500
    end
  end

  # REQUIRED PARAMS: sample_id
  # TODO - sample_status_changed - it need to be tested
  def sample_status_changed
    begin
      sample = Sample.find(params[:sample_id])
      allowed_contractor_ids = [637, 638, 659, 671] # epiexpert, nume, physikit, trime, luxbiotech=745
      inst_id = sample.rsc.InstitutionId
      notify = ApiAccount.includes(:contractor).where(contractor: {institution_id: inst_id}).where(contractor_id: allowed_contractor_ids).any? 
      Notification::SampleChangedJob.perform_later(params[:sample_id]) if notify
      render json: { message: "notification was properly scheduled" }, status: 200
    rescue StandardError => ex
      pp ex
      render json: { message: "there are problems with scheduling notification job"}, status: 500
    end
  end

end


