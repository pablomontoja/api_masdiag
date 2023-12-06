module Patients
	module FoodForTheBrainModificator
		extend ActiveSupport::Concern

		included do
			#TODO the institution.name should be changed to id
	    after_create :disable_sending_results_on_mail, if: Proc.new { |patient| patient.contractor.institution.name == "FoodForTheBrain" }

	    def disable_sending_results_on_mail
	      self.update_columns(send_results_on_mail: false)
	    end
	  end
		
	end
end