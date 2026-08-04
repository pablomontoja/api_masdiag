class Nume::KitController < Fv1::KitController
  include NumeCheck

  def check_code
    @current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: code_params)

    response_hash = {}
    response_hash[:code] = code_params
    response_hash[:masdiag_check_sum] = control_sum(code_params)

    if @current_rsc.nil?
      response_hash[:message] = "A such sample code was not found for your institution"
      json_response(response_hash, :unprocessable_content)
      return
    end

    response_hash[:test_names] = @current_rsc.projects.map(&:eng_name)
    response_hash[:test_ids] = @current_rsc.projects.map(&:Id)
    response_hash[:kit_type] = @current_rsc.package&.product&.name

    case @current_rsc.package&.product&.id
    when 15
      response_hash[:kit_type] = "VITAMIN D PLUS"
    when 16
      response_hash[:kit_type] = "VITAMIN D STANDARD"
    end

    json_response(response_hash)
  end
end
