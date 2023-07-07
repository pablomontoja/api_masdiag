class V1::SampleController < ApplicationController

  def create
    current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: sample_params[:code])

    if current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution." }, :unprocessable_entity)
      return
    end

    if current_rsc&.expiry_date < Time.zone.now
      json_response({ message: "The DBS card is expired." }, :unprocessable_entity)
      return
    end

    if current_rsc&.reserved_tests.count.zero?
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

    if @sample.save!(context: :v1)
      json_response(SampleResource.new(@sample), :created)
    else
      json_response({message: @sample.errors}, :unprocessable_entity)
    end
  end

  def destroy
    rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: sample_code)
    sample = Sample.where(AcceptanceDate: nil).find_by(Code: sample_code)
    if rsc.nil?
      json_response({ message: "A such sample code was not found for your institution." }, :unprocessable_entity)
      return
    end

    if sample.nil?
      json_response({ message: "This sample cannot be deleted." }, :unprocessable_entity)
      return
    end

    if sample.destroy
      head :no_content
    end
  end


  private

  def sample_code
    params.require(:code).upcase
  end

  def sample_params
    params.require(:sample).permit(:id, :code, :sample_collection_date, patient_attributes: [:first_name, :last_name, :email, :pesel, :contractor_id, :birth_date, :gender, :id_document, :id_number]).each_value do |value|
      case value
      when String
        value.try(:strip!)
      when ActionController::Parameters
        value.each_value { |value| value.try(:strip!) }
      end
    end
  end

end

# "sample"=>
# {"Code":"JV4XJ", "sample_collection_date":"2022-04-10", "patient_attributes":{"email":"email@domain.com", "email_confirmation":"email@domain.com", "FirstName":"Paweł", "LastName":"Świder", "Pesel":"73080335755", "BirthDate":"", "Gender":"1", "ContractorId":"336"}


# {
#   "sample": {
#     "code": "JV4XJ",
#     "sample_collection_date": "2022-04-10",
#     "patient_attributes": {
#       "email": "email@domain.com",
#       "first_name": "Paweł",
#       "last_name": "Świder",
#       "pesel": "73080335755",
#       "is_foreigner": false,
#       "birth_date": "",
#       "gender": "0",
#     }
#   }
# }

# {
#     "sample": {
#         "code": "JV4XJ",
#         "sample_collection_date": "2022-04-10",
#         "patient_attributes": {
#             "email": "email@domain.com",
#             "first_name": "Paweł",
#             "last_name": "Świder",
#             "pesel": "73080335755",
#             "birth_date": "1973-08-03",
#             "gender": "0",
#             "id_document": 0,
#             "id_number": "AA"
#         }
#     }
# }

# N4GZ4 Q4TEY S672U LZHPF CJIB7 Q6NFI UPTBV QJDKW KRVRZ Y1ACD BGIJQ WN46G AJ7YA ZFMRK PBFBB JRXIM 2WQ52 D1ZKU IFAI4 XDSFV VXAFI LPUEL DDBX7 U93T2 S9RAE 883JK TVQUU FD4KI T9QV3 RR7MY BL29A YCZJ5 MR1XW VSHWQ 51WZ2 9A991 IZEVW SGBAK BE8WB F3UQA 5GGXA MGYA5 231ZS 5HMAV L3183 8E1F3 PZVRN TVQB6 GF43J 4KVCF AD4ZE PKF4C 18JMB CVS1P PAIX1 UHRFG
