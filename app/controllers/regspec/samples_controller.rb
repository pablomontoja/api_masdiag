class Regspec::SamplesController < ApplicationController
	include MasdiagCheck

	# POST   /regspec/patients 
	def create
		db_rsc = ReservedSampleCode.find_by(Code: sample_params[:code])

		if db_rsc.nil?
			ActiveRecord::Base.transaction do			
				add_rsc()
			end
		end
		
		db_sample = Sample.find_by(Code: sample_params[:code])
		
		if db_sample.present?
			json_response({ message: "Sample already exist" }, :unprocessable_entity)
			return
		end

    @sample = V1::SampleCreator.call(sample_params, @current_rsc)

    @sample.validate

    if @sample.save!(context: :fv1)
      json_response({ sample_id: @sample.Id, patient_id: @sample.PatientId }, :created)
    else
      json_response({ message: @sample.errors }, :unprocessable_entity)
    end		
	end


	# PATCH  /regspec/patients/:id
	def update
		sample = Sample.find(params[:id])
		if sample.update(update_params)
			json_response({ })
		else
			pp sample.errors
			json_response({ message: sample.errors.map(&:message).join(", ") }, :unprocessable_entity)
		end
	end


	private

	def sample_params
    params.require(:sample).permit(:id, :code, :sample_collection_date, project_ids: [], patient_attributes: [:first_name, :last_name, :email, :pesel, :contractor_id, :birth_date, :gender, :id_document, :id_number]).each_value do |value|
      case value
      when String
        value.try(:strip!)
      when ActionController::Parameters
        value.each_value { |value| value.try(:strip!) }
      end
    end
  end

  def update_params
    params.require(:sample).permit(:code, :sample_collection_date).each_value do |value|
      case value
      when String
        value.try(:strip!)
      when ActionController::Parameters
        value.each_value { |value| value.try(:strip!) }
      end
    end
  end

  # def add_reserved_tests
  # 	if @sample.rsc.nil?
  # 		add_rsc()
  # 	else
	#   	@sample.rsc.update!(IsRetailSale: true, expiry_date: 1.year.since)
	#   	@sample.project_ids.each do |project_id|
	#   		next if project_id.blank?
	#   		@sample.rsc.reserved_tests.create!(project_id: project_id)
	#   	end
	#   end
  # end

  def add_rsc
		contractor_id = sample_params[:patient_attributes][:contractor_id]
		institution_id = Contractor.find(contractor_id)&.institution_id

		@current_rsc = ReservedSampleCode.create!(Code: sample_params[:code], CreatedAt: Time.current, CreatedById: 1, 
															IsRetailSale: true, 
															expiry_date: Time.now + 12.months, 
															InstitutionId: institution_id,
															MaterialType: :urine,
															material_handler: :urine_vial,
															reserved_by_contractor_id: contractor_id,
															comment: "")
		sample_params[:project_ids].reject(&:blank?).each { |id| @current_rsc.reserved_tests.create(project_id: id) if id.present? }	
  end

end
