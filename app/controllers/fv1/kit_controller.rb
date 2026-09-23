class Fv1::KitController < V1::KitController

  # {data: {code: "ASDFG", test_ids: [1,2]}}
  def assign_tests
    @current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: assignment_params[:code])

    if @current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution" }, :unprocessable_content)
      return
    end

    @sample = Sample.find_by(Code: assignment_params[:code])

    if @sample.present? && @sample&.IsWrongRegistration == false
      json_response({ message: "Tests for this sample cannot be assigned" }, :unprocessable_content)
      return
    end

    requested_test_ids = assignment_params[:test_ids].map(&:to_i)

    if @current_rsc.reserved_tests.exists?(project_id: 26) || (requested_test_ids.include?(26) && @current_rsc.reserved_tests.exists?)
      json_response({ message: "Tests for this sample collection card have already been assigned and cannot be changed" }, :unprocessable_content)
      return
    end

    if requested_test_ids.include?(26) && !@current_rsc.dbs_i4?
      json_response({ message: "A Glutathione test can only be assigned to a special DBS sample collection card" }, :unprocessable_content)
      return
    end

    assignment = validate_assignment(assignment_params[:test_ids])
    if assignment.invalid
      json_response({message: assignment.errors.join("; ")}, :unprocessable_content)
      return
    end

    @contractor_id = Current.api_account.contractor.Id

    ActiveRecord::Base.transaction do
      @current_rsc.reserved_tests.destroy_all
      assignment_params[:test_ids].each do |test|
        @current_rsc.reserved_tests.create!(project_id: remap_project_id(test.to_i, Current.api_account.institution.id))
      end
      @current_rsc.update!(IsRetailSale: true, InstitutionId: Current.api_account.institution.id, reserved_by_contractor_id: Current.api_account.institution.api_contractor_id)
    end

    # Notify the partner only once the assignment has actually committed.
    # AssignKitTestsJob posts to an external API and retries on failure, so
    # enqueueing it inside the transaction would tell the partner about an
    # assignment that a rollback then discards, with no way to withdraw it.
    assign_tests_in_lalen_api

    head :no_content
  end

private

  OMEGA_ACIDS_PROJECT_ID = 21
  OMEGA3_INDEX_PROJECT_ID = 34
  OMEGA3_INDEX_INSTITUTION_IDS = [83, 95]

  def remap_project_id(project_id, institution_id)
    return OMEGA3_INDEX_PROJECT_ID if OMEGA3_INDEX_INSTITUTION_IDS.include?(institution_id) && project_id == OMEGA_ACIDS_PROJECT_ID
    project_id
  end

  def assign_tests_in_lalen_api
    return if Current.api_account.institution.id != 83 # FFTB
    return if assignment_params[:test_ids].map(&:to_i).uniq.count > 3 # blockade for trying the DRIFTs assignement
    api_keys = assignment_params[:test_ids].map(&:to_i).uniq.filter_map { |t| V1::Common::LALEN_TEST_API_KEYS[t] }
    return if api_keys.empty?

    LalenApi::AssignKitTestsJob.perform_later(@current_rsc.Code, api_keys)
  end


end
