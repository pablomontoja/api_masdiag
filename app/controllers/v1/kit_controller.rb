class V1::KitController < ApplicationController

  def check_code
    @current_rsc = ReservedSampleCode.where(InstitutionId: Current.api_account.institution.id).find_by(Code: code_params)

    response_hash = {}
    response_hash[:code] = code_params
    response_hash[:masdiag_check_sum] = control_sum(code_params)

    if @current_rsc.nil?
      response_hash[:message] = "A such sample code was not found for your institution"
      json_response(response_hash, :unprocessable_entity)
      return
    end

    response_hash[:test_names] = @current_rsc.projects.map(&:eng_name)
    response_hash[:test_ids] = @current_rsc.projects.map(&:Id)
    response_hash[:kit_type] = @current_rsc.package&.product&.name

    json_response(response_hash)
  end

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
      json_response({ message: "Tests for this sample have already been assigned and cannot be changed" }, :unprocessable_entity)
      return
    end

    if requested_test_ids.include?(26) && !@current_rsc.dbs_i4?
      json_response({ message: "Test 26 can only be assigned to a dbs_i4 material handler" }, :unprocessable_entity)
      return
    end

    assignment = validate_assignment(assignment_params[:test_ids])
    if assignment.invalid
      json_response({message: assignment.errors.join("; ")}, :unprocessable_entity)
      return
    end

    @contractor_id = Current.api_account.contractor.Id

    ActiveRecord::Base.transaction do
      @current_rsc.retrieve_institution_tests

      @current_rsc.reserved_tests.destroy_all
      assignment_params[:test_ids].each do |test|        
        @current_rsc.reserved_tests.create!(project_id: test)
      end
      @current_rsc.update!(IsRetailSale: true, InstitutionId: Current.api_account.institution.id)

      build_transactions()
    end
    head :no_content
  end



  private

  def code_params
    params.require(:code).upcase
  end

  def assignment_params
    params.require(:data).permit(:code, test_ids:[])
  end

  def validate_assignment(test_ids)
    allowed_weight = 2
    allowed_weight = 4 if Current.api_account.institution.id == 83 # Food for the brain
    test_ids.uniq!
    return OpenStruct.new(invalid: true, errors: ["test_ids array can not be empty"]) if test_ids.map(&:to_i).reject(&:zero?).compact.empty?

    avail_test = V1::Common::AVAILABLE_TESTS
    requested_test = avail_test.select{|a| test_ids.map(&:to_i).include?(a[:id])}
    return OpenStruct.new(invalid: true, errors: ["One or more tests can not be assigned"]) if test_ids.map(&:to_i).reject(&:zero?).compact.size != requested_test.compact.size

    requested_material = requested_test.map { |t| t[:material] }.uniq
    requested_weight = requested_test.select{|t| t[:material] == "DBS"}.sum {|t| t[:weight]}
    errors = []
    errors << "Assignment of tests for 2 different types of material is not possible" if (requested_material.count > 1)
    errors << "Weight limit exceeded for DBS material" if requested_material.include?("DBS") && requested_weight > allowed_weight
    return errors.compact.empty? ? OpenStruct.new(invalid: false) : OpenStruct.new(invalid: true, errors: errors)
  end

  def control_sum(code)
    result = "ok"
    if code.match?(/[oO0]/i)
      result = "invalid" if code.match?(/[oO0]/i)
    else
      ul_sum = 0
      modulo34 = '123456789ABCDEFGHIJKLMNPQRSTUVWXYZ'
      (0..code.length - 2).step(2).each { |i| ul_sum += (code[i].ord - '1'.ord) * (i + 1) }
      ul_sum *= 3
      (1..code.length - 2).step(2).each { |i| ul_sum += (code[i].ord - '1'.ord) * i }
      controlchar = modulo34[ul_sum % 34]
      result = "invalid" if controlchar != code[-1]
    end
    return result
  end

  def build_transactions
    @current_rsc.projects.map(&:Id).each do |p_id|
      @current_rsc.test_transactions.create!(contractor_id: @contractor_id, project_id: p_id, amount_change: -1)
    end
  end

end
