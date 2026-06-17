class Fv1::KitController < V1::KitController

  # {data: {code: "ASDFG", test_ids: [1,2]}}
  def assign_tests
    @current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: assignment_params[:code])

    if @current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution" }, :unprocessable_entity)
      return
    end

    @sample = Sample.find_by(Code: assignment_params[:code])

    if @sample.present? && @sample&.IsWrongRegistration == false
      json_response({ message: "Tests for this sample cannot be assigned" }, :unprocessable_entity)
      return
    end

    requested_test_ids = assignment_params[:test_ids].map(&:to_i)

    if requested_test_ids.include?(26) && @current_rsc.reserved_tests.exists?
      json_response({ message: "Tests for this sample collection card have already been assigned and cannot be changed" }, :unprocessable_entity)
      return
    end

    if requested_test_ids.include?(26) && !@current_rsc.dbs_i4?
      json_response({ message: "A Glutathione test can only be assigned to a special DBS sample collection card" }, :unprocessable_entity)
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
      @current_rsc.update!(IsRetailSale: true, InstitutionId: Current.api_account.institution.id, reserved_by_contractor_id: Current.api_account.institution.api_contractor_id)
    end
    
    head :no_content
  end

end
