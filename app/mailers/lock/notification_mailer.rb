module Lock
	class NotificationMailer < ApplicationMailer
		default :template_path => "mailers/#{self.name.underscore}"
 		
 		def locked_kit_appeared_in_lab(note)
 			return nil if note.nil?
 			@note = note
 			mail(to: ["maryia.vasiutsina@masdiag.pl", "renata.halak@masdiag.pl", "pawel.swider@masdiag.pl"], subject: 'Kit Lock Alert')
 		end

	end
end
