class V1::KitController < ApplicationController

  # {data: {code: "ASDFG", test_ids: [1,2]}}
  def assign_tests
    # byebug
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

    ActiveRecord::Base.transaction do
      @current_rsc.reserved_tests.destroy_all
      assignment_params[:test_ids].each do |test|
        @current_rsc.reserved_tests.create(project_id: test)
      end
      @current_rsc.update(IsRetailSale: true, InstitutionId: Current.api_account.institution.id)
    end
    head :no_content

  end



  private

  def assignment_params
    params.require(:data).permit(:code, test_ids:[])
  end

  def validate_assignment(test_ids)
    # byebug
    return OpenStruct.new(invalid: true, errors: ["test_ids array can not be empty"]) if test_ids.compact.reject(&:empty?).empty?

    avail_test = V1::Common::AVAILABLE_TESTS
    requested_test = avail_test.select{|a| test_ids.map(&:to_i).include?(a[:id])}
    return OpenStruct.new(invalid: true, errors: ["One or more tests can not be assigned"]) if test_ids.compact.reject(&:empty?).size != requested_test.compact.size

    requested_material = requested_test.map { |t| t[:material] }.uniq
    requested_weight = requested_test.select{|t| t[:material] == "DBS"}.sum {|t| t[:weight]}
    errors = []
    errors << "Assignment of tests for 2 different types of material is not possible" if (requested_material.count > 1)
    errors << "Weight limit exceeded for DBS material" if requested_material.include?("DBS") && requested_weight > 2
    return errors.compact.empty? ? OpenStruct.new(invalid: false) : OpenStruct.new(invalid: true, errors: errors)
  end

end
