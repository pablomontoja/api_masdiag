module MasdiagRecurring
	class Myjob < ApplicationJob
		
		def perform(args)
			pp args
			args
		end		
		
	end
end