module Lock
	class NotificationMailer < ApplicationMailer
		default :template_path => "mailers/#{self.name.underscore}"
 		
 		def locked_kit_appeared_in_lab(note)
 			return nil if note.nil?
 			@note = note
 			mail(to: ["pawel.swideri@masdiag.pl"], subject: 'Kit Lock Alert')
 			# mail(to: ["dariusz.kolodynski@masdiag.pl", "maryia.vasiutsina@masdiag.pl", "renata.halak@masdiag.pl"], subject: 'Kit Lock Alert')
 		end

	end
end
