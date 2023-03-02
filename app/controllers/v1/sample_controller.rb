class V1::SampleController < ApplicationController

  def create
    binding.break
    current_rsc = ReservedSampleCode.find_by(Code: sample_params[:code])

    if current_rsc.nil?
      json_response({ message: "The sample does not have assigned tests." }, :unprocessable_entity)
      return
    end

    @sample = Sample.where(IsWrongRegistration: true)
    .includes(measurements: %i[project result])
    .find_by(Code: current_rsc.Code.upcase)

    @sample = if @sample.nil?
      V1::SampleCreator.call(sample_params, current_rsc)
    else
      V1::WrongSampleUpdater.call(@sample, sample_params, current_rsc)
    end

    @sample.validate

    if @sample.save!
      json_response(@sample, :created)
    else
      json_response({message: @sample.errors}, :unprocessable_entity)
    end

  end


  private

  def sample_params
    params.require(:sample).permit(:id, :code, :sample_collection_date, patient_attributes: [:first_name, :last_name, :pesel, :contractor_id, :is_foreigner, :birth_date, :gender, :id_document, :id_number])
  end

end

# "sample"=>
# {"Code":"JV4XJ", "sample_collection_date":"2022-04-10", "patient_attributes":{"email":"pablomontoja2@gmail.com", "email_confirmation":"pablomontoja2@gmail.com", "FirstName":"Paweł", "LastName":"Świder", "Pesel":"83070212412", "BirthDate":"", "Gender":"1", "ContractorId":"336"}
