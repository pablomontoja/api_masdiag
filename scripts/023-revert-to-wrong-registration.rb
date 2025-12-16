codes = %w[EUAC407260 EUKZITDT EUVEMABL EUETFULG EU3PZACN EU32BQUW]

ActiveRecord::Base.transaction do
	Sample.where(Code: codes).each do |sample|
		sample.update!(IsWrongRegistration: true, WasWrongRegistration: false, 
									PatientId: 4798, RegistrationDate: sample.AcceptanceDate, 
									WrongRegistrationStatus: 1)
	end
end