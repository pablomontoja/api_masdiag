class Regspec::ContractorsController < ApplicationController
	include MasdiagCheck

	# regspec_institutions POST   /regspec/contractors 
	def create
		contractor = Contractor.new(final_params)
		pass = SecureRandom.alphanumeric(32)
		contractor.password = pass
		contractor.password_confirmation = pass
		contractor.confirmed_at = Time.now
		contractor.approved = true
		contractor.are_notifications_enabled = false
		contractor.type_of_contractor = 0
		contractor.phone = nil
		contractor.invalid_first_or_last_name = false
		contractor.patient_is_orderer = false
		contractor.is_super_contractor = false
		contractor.can_add_samples = tru

		if contractor.save
			json_response({ contractor_id: contractor.id }, :created)
		else
			json_response({ message: contractor.errors.map(&:message).join(", ") }, :unprocessable_entity)
		end		
	end


	# regspec_institution PATCH  /regspec/contractors/:id
	def update
		contractor = Contractor.find(params[:id])
		if contractor.update(final_params)
			json_response({})
		else
			pp contractor.errors
			json_response({ message: contractor.errors.map(&:message).join(", ") }, :unprocessable_entity)
		end
	end


	private

  #  REGSPEC has the following attributes of department
	# Table name: departments
	#
	#  id             :bigint           not null, primary key
	#  name           :string(255)
	#  email          :string(255)
	#  institution_id :integer
	#  created_at     :datetime         not null
	#  updated_at     :datetime         not null
	def contractor_params
		params.require(:contractor).permit(:name, :email, :institution_id)		
	end

	def final_params
		cp = contractor_params
		cp.merge!(
			Name: nil,                                                        
			Address: nil,
			first_name: cp[:name],
			last_name: "",
			nip: nil
		).except(:name)
	end

end
