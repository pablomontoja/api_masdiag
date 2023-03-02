class V1::SampleCreator < ApplicationService
  def initialize(params, rsc)
    @params = params.except(:project_ids)
    @project_ids = rsc.project_ids
    @rsc = rsc
    @sample = Sample.new
  end

  def call
    create_sample_with_default_attributes()
    add_measurements()
    add_selected_tests()
    @sample
  end

  def create_sample_with_default_attributes
    params_preparation()
    @sample.attributes = @params
    @sample.MaterialType = @rsc.MaterialType
    # CapillaryBlood = 0,
    # BloodSerum,      surowica
    # BloodPlasma,     osocze
    # Hair,
    # Nails,
    # Urine,
    # Saliva
  end

  def add_measurements
    @project_ids.each { |id| @sample.measurements.build(Status: 7, ProjectId: id) }
  end

  def add_selected_tests
    selected_tests = {}
    @project_ids.each { |id| selected_tests[id.to_s] = [] }
    @sample.selected_tests = selected_tests.to_json
  end

  def params_preparation
    @params = Masdiag::ParamsRebuilder.call(@params)
    if !@params[:patient_attributes][:Pesel].blank?
      patient = @rsc.reserved_by&.patients&.find_by(Pesel: @params[:patient_attributes][:Pesel])
      patient = Contractor.find(@params[:patient_attributes][:ContractorId])&.patients&.find_by(Pesel: @params[:patient_attributes][:Pesel]) if patient.nil?
      patient.update!(email: @params[:patient_attributes][:email]) if patient
      @params = @params.except(:patient_attributes) if patient
      @params.merge!(PatientId: patient.Id) if patient
    end
    @params.merge!(RegistrationDate: Time.zone.now, IsWrongRegistration: false, WasWrongRegistration: false,
                   SampleState: 1, SampleStatus: 1, WrongRegistrationStatus: 0) # payment_status?
  end
end
