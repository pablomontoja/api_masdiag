class V1::WrongSampleUpdater < ApplicationService
  def initialize(sample, params, rsc)
    @params = params.except(:project_ids)
    @project_ids = rsc.project_ids
    @rsc = rsc
    @sample = sample
  end

  def call
    update_sample_attrs
    update_measurements

    if [4,5].include?(@sample.soaking_degree_id)
      @sample.measurements.destroy_all
      SendMailNotificationJob.perform_later("send_cancellation_notifications", @sample)
    else
      # SendNotificationAfterDelayedRegJob.perform_later(@sample.Id)
      SendMailNotificationJob.perform_later("send_notification_after_delayed_reg", @sample)
    end

    @sample
  end

  def update_sample_attrs
    params_preparation
    @sample.attributes = @params
  end

  def update_measurements
    existing_projects_ids = @sample.measurements.map(&:project).map(&:id)
    @project_ids -= existing_projects_ids
    @project_ids.each { |id| @sample.measurements.build(ProjectId: id, Status: 1) }
  end

  def params_preparation
    @params = Masdiag::ParamsMapper.call(@params, :sample)
    @params[:patient_attributes].merge!(ContractorId: Current.api_account.contractor_id) if @rsc.reserved_by.nil?
    @params[:patient_attributes].merge!(ContractorId: @rsc.reserved_by.Id) if !@rsc.reserved_by.nil?

    if !@params[:patient_attributes][:Pesel].blank?
      patient = @rsc.reserved_by&.patients&.find_by(Pesel: @params[:patient_attributes][:Pesel])
      patient = Contractor.find(Current.api_account.contractor_id)&.patients&.find_by(Pesel: @params[:patient_attributes][:Pesel]) if patient.nil?
      patient.update!(email: @params[:patient_attributes][:email]) if patient && @params[:patient_attributes][:email].present?
      @params = @params.except(:patient_attributes) if patient
      @params.merge!(PatientId: patient.Id) if patient
    else
      patient = Patient.where(FirstName: @params[:patient_attributes][:FirstName], LastName: @params[:patient_attributes][:LastName], Gender: @params[:patient_attributes][:Gender], BirthDate: @params[:patient_attributes][:BirthDate], ContractorId: @params[:patient_attributes][:ContractorId]).first
      @params = @params.except(:patient_attributes) if patient
      @params.merge!(PatientId: patient.Id) if patient
    end

    @params.merge!(RegistrationDate: Time.zone.now, IsWrongRegistration: false, WasWrongRegistration: true) # payment_status?
    @params[:WrongRegistrationStatus] = @sample.measurements.any?(&:result) ? 4 : 2
  end
end
