class Regspec::RegspecSyncController < ApplicationController
  http_basic_authenticate_with name: Rails.application.credentials.regspec[:name], password: Rails.application.credentials.regspec[:password]

  def push_sample
    @sample = Sample.find_by(Code: sample_params[:Code])
    if @sample&.rsc&.is_regspec_sample?
      sync(sample_params.except(:Code))
    end
    render json: {}, status: :ok
  end

  def push_patient
    samples = Sample.where(Code: patient_params[:codes])
    patient_ids = []
    if samples.any? { |s| s.rsc&.is_regspec_sample? }
      patient_ids << samples.pluck(:PatientId)
    end

    if patient_ids.uniq.one?
      Patient.find_by(Id: patient_ids.first).update(patient_params.except(:codes))
    end

    render json: {}, status: :ok
  end

  def cancel_sample    
    is_already_cancelled = !Sample.where.not(CancellationDate: nil).where(SampleStatus: 4).find_by(Code: cancellation_params[:sample_code]).nil?

    if is_already_cancelled
      render json: { error: "Sample already cancelled."}, status: 412
      return
    end

    sample = Sample.find_by(Code: cancellation_params[:sample_code])
    user = User.find_by(email: cancellation_params[:cancelled_by_email].strip.downcase)

    if sample.nil? || !sample&.rsc&.is_regspec_sample?
      render json: { error: "Sample not found or no connected to REGSPEC."}, status: 412
      return
    end

    ActiveRecord::Base.transaction do
      sample.update!(Comment: cancellation_params[:cancellation_reason].strip, SampleStatus: 4, CancelledById: user&.Id, CancellationDate: cancellation_params[:cancellation_date])
      
      rescue ActiveRecord::ActiveRecordError => exception
        Sentry.capture_exception(exception)
        render json: { error: "Error during sample cancellation saving: #{exception.inspect}"}, status: 412
        return
    end

    # TODO: MasdiagMailer::IndMailer#regspec_cancellation nie istnieje — metoda i szablon do napisania
    MasdiagMailer::IndMailer.regspec_cancellation(sample.Id).deliver_later if cancellation_params[:should_backup_kit_be_sent]
    render json: {}, status: :ok
  end


  private

  def sync(params)
    if @sample.accepted_in_lab?
      process_accepted_sample(params)
    else      
      process_not_accepted_sample(params)
      MasdiagMailer::SendAcceptanceNotificationsJob.perform_later([@sample.Id])
    end
  end

  def process_accepted_sample(params)
    @sample.update(params)
  end

  def process_not_accepted_sample(params)
    @sample.measurements.update_all(Status: 1)
    @sample.update(params.merge({SampleStatus: 2, SampleState: 2, soaking_degree_id: 1}))
  end

  def sample_params
    params.require(:sample).permit(:Code, :sample_collection_date, :AcceptanceDate)
  end

  def patient_params
    params.require(:patient).permit(:FirstName, :LastName, :Gender, :BirthDate, :Pesel, codes:[])
  end

  def cancellation_params
    params.require(:cancellation).permit(:sample_code, :cancellation_date, :cancellation_reason, :cancelled_by_email, :should_backup_kit_be_sent)
  end

end
