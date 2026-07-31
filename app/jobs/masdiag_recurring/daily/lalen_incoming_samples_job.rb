module MasdiagRecurring
  module Daily

    class LalenIncomingSamplesJob < ApplicationJob

      def perform
        settled_before = Note.where(key: "lalen-eu-incoming-samples-email", subject_type: "Sample").pluck(:subject_id)
        today_accepted_sample_ids = Sample.includes({ patient: :contractor }).where.not(AcceptanceDate: nil).where.not(Id: settled_before).where("Contractors.institution_id = ?", 89).pluck(:Id)

        return if today_accepted_sample_ids.flatten.blank?
        MasdiagRecurring::DailyLalenIncomingSamplesMailer.daily_mail(today_accepted_sample_ids).deliver_later
      end
    	
    end

  end
end