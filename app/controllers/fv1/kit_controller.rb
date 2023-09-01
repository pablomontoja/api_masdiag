class Fv1::KitController < V1::KitController

  # {data: {code: "ASDFG", test_ids: [1,2]}}
  def assign_tests
    @current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: assignment_params[:code])

    if @current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution" }, :unprocessable_entity)
      return
    end

    @sample = Sample.where.not(AcceptanceDate: nil).find_by(Code: assignment_params[:code])

    if !@sample.nil?
      json_response({ message: "Tests for this sample cannot be assigned" }, :unprocessable_entity)
      return
    end

    assignment = validate_assignment(assignment_params[:test_ids])
    if assignment.invalid
      json_response({message: assignment.errors.join("; ")}, :unprocessable_entity)
      return
    end

    @contractor_id = Current.api_account.contractor.Id

    ActiveRecord::Base.transaction do
      @current_rsc.reserved_tests.destroy_all
      assignment_params[:test_ids].each do |test|        
        @current_rsc.reserved_tests.create!(project_id: test)
      end
      @current_rsc.update!(IsRetailSale: true, InstitutionId: Current.api_account.institution.id)
    end
    head :no_content
  end

end
