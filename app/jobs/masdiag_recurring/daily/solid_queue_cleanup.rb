module MasdiagRecurring
	module Daily

		class SolidQueueCleanup < ApplicationJob
			
			def perform
				SolidQueue::Job.clear_finished_in_batches(finished_before: 1.month.ago)
			end		
			
		end

	end
end