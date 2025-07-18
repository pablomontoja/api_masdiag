class Regspec::PatientsController < ApplicationController
	include MasdiagCheck

	# POST   /regspec/patients 
	# def create
	# 	patient = Patient.new(final_params)

	# 	if patient.save
	# 		json_response({ patient_id: patient.id }, :created)
	# 	else
	# 		json_response({ message: patient.errors.map(&:message).join(", ") }, :unprocessable_entity)
	# 	end		
	# end


	# PATCH  /regspec/patients/:id
	def update
		patient = Patient.find(params[:id])
		if patient.update(update_params)
			json_response({})
		else
			pp patient.errors
			json_response({ message: patient.errors.map(&:message).join(", ") }, :unprocessable_entity)
		end
	end


	private

  #  REGSPEC has the following attributes of patient
	#  id                  :bigint           not null, primary key
	#  first_name          :string(255)
	#  last_name           :string(255)
	#  sex                 :integer
	#  birthdate           :date
	#  pesel               :string(255)
	#  confirmed_diagnosis :string(255)
	#  remarks             :string(255)
	#  contractor_id       :integer
	#  is_foreigner        :boolean
	#  created_at          :datetime         not null
	#  updated_at          :datetime         not null
	#  id_card_nr          :string(255)
	#
	def patient_params
		params.require(:patient).permit(:first_name, :last_name, :gender, :birth_date, :pesel)		
	end

	def update_params
		pat = patient_params
		pat.merge!(
			FirstName: pat[:first_name],                                                        
			LastName: pat[:last_name],
			Pesel: pat[:pesel],
			BirthDate: pat[:birth_date],
			Gender: pat[:gender]
		).except(:first_name, :last_name, :gender, :birth_date, :pesel)
	end

end 