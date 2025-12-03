class MeasurementSummariesMailer < ApplicationMailer
		default :template_path => "mailers/#{self.name.underscore}"
 		
 		def monthly_summary(ago = 1)
 			@ago = ago
 			@measurement_summaries = MeasurementSummary.includes(:institution).order("institutions.name ASC").where(from_date: ago.month.ago.beginning_of_month..ago.month.ago.end_of_month)
 			mail(to: ["tomasz.bienkowski@masdiag.pl", "lalen.dogan@masdiag.pl", "anna.grabowska@masdiag.pl", "pawel.swider@masdiag.pl"], subject: 'Summary of measurements from the previous month')
 		end

end