module Patients
	module FoodForTheBrainModificator
		extend ActiveSupport::Concern
		# This concern is responsible for disabling the sending of e-mails via MasdiagMailer.
		# FFTB is not able to send parameters without an email address, but does not want masdiag to send the result as stated in the MasdiagAPI documentation

		included do
			after_create :disable_sending_results_on_mail, if: Proc.new { |patient| patient.contractor.institution.name == "FoodForTheBrain" } if Rails.env.development? || Rails.env.staging?
			after_create :disable_sending_results_on_mail, if: Proc.new { |patient| patient.contractor.institution.id == 83 } if Rails.env.production? # "FoodForTheBrain" 

	    def disable_sending_results_on_mail
	      self.update_columns(send_results_on_mail: false)
	    end
	  end
		
	end
end