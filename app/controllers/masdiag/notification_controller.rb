class Masdiag::NotificationController < ApplicationController
  include MasdiagCheck

  # NO REQUIRED PARAMS
  # TODO - trigger - it need to be tested
  def trigger
    begin
      errors = []
      ids = ApiAccount.pluck(:contractor_id)
      meas_ids = Measurement.includes(sample: :patient).where(Status: 5).where(Patients: {ContractorId: ids}).pluck(:Id)
      sent_meas_ids = ResultSendingEvent.where(sent_through: 6, measurement_id: meas_ids).where.not("address LIKE ?", "%lalen%").pluck(:measurement_id)
      meas_ids = meas_ids - sent_meas_ids
      # @meases_done = Hash.new

      Measurement.where(Id: meas_ids.uniq).each do |meas|
        Notification::SendResultJob.perform_later(meas.Id)
      end

      lalen_ids = Contractor.where(institution_id: V1::Common::LALEN_INSTITUTION_IDS).pluck(:Id)
      lalen_meas_ids = Measurement.includes(sample: :patient).where(Status: 5, AuthorizedAt: DateTime.parse("09 Sep 2024 12:00:00.000000000 UTC +00:00")..nil).where(Patients: {ContractorId: lalen_ids}).pluck(:Id)
      lalen_sent_meas_ids = ResultSendingEvent.where(sent_through: 6, measurement_id: lalen_meas_ids).where("address LIKE ?", "%lalen%").where.not("address LIKE ?", "%(sample info delivery)%").pluck(:measurement_id)
      lalen_meas_ids = lalen_meas_ids - lalen_sent_meas_ids

      Measurement.where(Id: lalen_meas_ids.uniq).each do |meas|
        Notification::LalenResultSender.perform_later(meas)
      end

      render json: { message: "result notifications was properly scheduled" }, status: 200
    rescue StandardError => ex
      Sentry.capture_exception(ex)
      render json: { message: "there are problems with scheduling notification jobs"}, status: 500
    end
  end

  # REQUIRED PARAMS: sample_id
  # TODO - sample_status_changed - it need to be tested
  def sample_status_changed
    begin
      sample = Sample.find(params[:sample_id])

      Lock::CheckJob.perform_later(sample&.rsc)

      allowed_contractor_ids = [637, 638, 659, 671, 699] # epiexpert, nume, physikit, trime, FFTB, luxbiotech=745
      inst_id = sample.rsc&.InstitutionId
      if inst_id.nil?
        puts "-------------------------------------------------------------"
        puts "Masdiag::NotificationController#sample_status_changed aborted"
        puts "sample #{sample.Code} doesn't have ReservedSampleCode."
        puts "-------------------------------------------------------------"
        return
      end      

      if V1::Common::LALEN_INSTITUTION_IDS.include?(inst_id)
        ::LalenApi::RegisterKitJob.perform_now(sample) if inst_id == 89
        Notification::SampleChangedJob.perform_later(sample.Id)
      else
        notify = ApiAccount.includes(:contractor).where(contractor: {institution_id: inst_id}).where(contractor_id: allowed_contractor_ids).any? 
        Notification::SampleChangedJob.perform_later(params[:sample_id]) if notify
      end
      
      render json: { message: "notification was properly scheduled" }, status: 200
    rescue StandardError => ex
      Sentry.capture_exception(ex)
      render json: { message: "there are problems with scheduling notification job"}, status: 500
    end
  end

end


