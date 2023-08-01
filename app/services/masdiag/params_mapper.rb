class Masdiag::ParamsMapper < ApplicationService
  def initialize(params, resource)
    @params = params.to_h
    @resource = resource
  end

  def call
    case @resource
    when :sample
      @params[:Code] = (@params.delete :code).upcase
      @params.dig(:patient_attributes)[:FirstName] = @params.dig(:patient_attributes).delete :first_name
      @params.dig(:patient_attributes)[:LastName] = @params.dig(:patient_attributes).delete :last_name
      @params.dig(:patient_attributes)[:Pesel] = @params.dig(:patient_attributes).delete :pesel
      @params.dig(:patient_attributes)[:BirthDate] = @params.dig(:patient_attributes).delete :birth_date
      @params.dig(:patient_attributes)[:Gender] = @params.dig(:patient_attributes).delete :gender
      @params.dig(:patient_attributes)[:ContractorId] = @params.dig(:patient_attributes).delete :contractor_id
      @params.dig(:patient_attributes)[:email] = nil if @params.dig(:patient_attributes)[:email] == "null"
    end

    @params
  end
end

# {"Code":"JV4XJ", "sample_collection_date":"2022-04-10", "patient_attributes":{"email":"pablomontoja2@gmail.com", "email_confirmation":"pablomontoja2@gmail.com", "FirstName":"Paweł", "LastName":"Świder", "Pesel":"83070212412", "BirthDate":"", "Gender":"1", "ContractorId":"336"}
