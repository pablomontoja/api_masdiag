class Lalen::KitController < Fv1::KitController
  include LalenCheck

  def check_code
    @current_rsc = ReservedSampleCode.where(InstitutionId: V1::Common::LALEN_INSTITUTION_IDS).find_by(Code: code_params)

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

    case @current_rsc.package&.product&.id
    when 15
      response_hash[:kit_type] = "VITAMIN D PLUS"
    when 16
      response_hash[:kit_type] = "VITAMIN D STANDARD"
    end

    json_response(response_hash)

    rescue StandardError => e
      json_response({ message: e.message }, :unprocessable_entity)
  end

  # {data: {code: "ASDFG", test_ids: [1,2]}}
  def assign_tests
    @current_rsc = ReservedSampleCode.where(InstitutionId: V1::Common::LALEN_INSTITUTION_IDS).find_by(Code: assignment_params[:code])

    if @current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution" }, :unprocessable_entity)
      return
    end

    @sample = Sample.find_by(Code: assignment_params[:code])

    if @sample.present? && @sample&.IsWrongRegistration == false
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

  # POST /kits/declare
  # json example: { code: "ASDFGQWERTY", expiry_date: "2026-10-31", material_handler: "dbs_faps", test_ids: [2, 3] }
  # possible material_handlers: dbs_faps, dbs_nem, dbs_bht, dbs_tfn, blood_vial, urine_vial
  # response: NO_CONTENT, STATUS 204
  def declare
    material_type = MaterialHandlers::MATERIAL_TYPE_BASED_ON_MODIFICATOR[declare_params[:material_handler].to_sym] || :dbs
    masdiag_material_handler = { dbs_faps: :dbs_f4, dbs_nem: :dbs_n4, dbs_bht: :dbs_b4, dbs_tfn: :dbs_t4, urine_vial: :urine_vial, blood_vial: :blood_vial }

    assignment = validate_assignment(declare_params[:test_ids])
    if assignment.invalid
      json_response({message: assignment.errors.join("; ")}, :unprocessable_entity)
      return
    end

    ActiveRecord::Base.transaction do
      inst_id = get_lalen_institution(declare_params[:code])

      rsc = ReservedSampleCode.create!(
                                Code: declare_params[:code],
                                CreatedAt: Time.current,
                                assignment_date: Time.current,
                                CreatedById: 1, 
                                IsRetailSale: true, 
                                expiry_date: declare_params[:expiry_date], 
                                InstitutionId: inst_id,
                                MaterialType: material_type,
                                material_handler: masdiag_material_handler[declare_params[:material_handler].to_sym]
                              )
      declare_params[:test_ids].each do |test|        
        rsc.reserved_tests.create!(project_id: test)
      end
    end

    # head :no_content
    json_response({}, :created)

    rescue StandardError => e
      json_response({ message: e.message }, :unprocessable_entity)
  end

  # POST /kits/declare/generic
  # json example: { code: "ASDFGQWERTY", expiry_date: "2026-10-31", material_handler: "dbs_faps" }
  # possible material_handlers: dbs_faps, dbs_nem, dbs_bht, dbs_tfn, blood_vial, urine_vial
  # response: NO_CONTENT, STATUS 204
  def declare_generic
    material_type = MaterialHandlers::MATERIAL_TYPE_BASED_ON_MODIFICATOR[declare_generic_params[:material_handler].to_sym] || :dbs
    masdiag_material_handler = { dbs_faps: :dbs_f4, dbs_nem: :dbs_n4, dbs_bht: :dbs_b4, dbs_tfn: :dbs_t4, urine_vial: :urine_vial, blood_vial: :blood_vial }

    ActiveRecord::Base.transaction do
      inst_id = get_lalen_institution(declare_generic_params[:code])

      rsc = ReservedSampleCode.create!(
                                Code: declare_generic_params[:code],
                                CreatedAt: Time.current,
                                assignment_date: Time.current,
                                CreatedById: 1, 
                                IsRetailSale: false, 
                                expiry_date: declare_generic_params[:expiry_date], 
                                InstitutionId: inst_id,
                                MaterialType: material_type,
                                material_handler: masdiag_material_handler[declare_generic_params[:material_handler].to_sym]
                              )
    end

    # head :no_content
    json_response({}, :created)

    rescue StandardError => e
      json_response({ message: e.message }, :unprocessable_entity)
  end

  # DELETE /kits/remove/declared/:code
  # response: NO_CONTENT, STATUS 204
  def destroy_declared
    @current_rsc = ReservedSampleCode.where(InstitutionId: V1::Common::LALEN_INSTITUTION_IDS).find_by(Code: code_params)

    if @current_rsc.nil?
      json_response({ message: "A such sample code was not found for your institution" }, :unprocessable_entity)
      return
    end

    @sample = Sample.find_by(Code: code_params)
    if @sample.present? && @sample&.IsWrongRegistration == false
      json_response({ message: "This kit declaration cannot be removed" }, :unprocessable_entity)
      return
    end

    @current_rsc.destroy

    head :no_content

    rescue StandardError => e
      json_response({ message: e.message }, :unprocessable_entity)
  end

private

  def declare_params
    params.permit(:expiry_date, :material_handler, :code, test_ids: [])
  end

  def declare_generic_params
    params.permit(:expiry_date, :material_handler, :code)
  end
  # def get_masdiag_project_id(api_test_name)
  #   avail_test = V1::Common::AVAILABLE_TESTS
  #   avail_test.find{ |t| t[:name] == api_test_name }&.dig(:id)
  # end

  def get_lalen_institution(barcode)
    case barcode[0, 2]
    when "EU"
      89
    when "AU"
      85
    else
      raise StandardError.new("Recognition of the Lalen institution on the basis of the barcode was unsuccessful.")
    end
  end
  

end
