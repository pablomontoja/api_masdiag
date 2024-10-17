module Lock
	class CheckJob  < ApplicationJob
		queue_as :background

		def perform(rsc)
			return nil if rsc.nil?
			@rsc = rsc

			note = Note.find_by(key: "kit-lock", subject: @rsc)
			return nil if note.nil?

			Lock::NotificationMailer.locked_kit_appeared_in_lab(note).deliver_now
		end

	end
end