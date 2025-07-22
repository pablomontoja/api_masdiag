module MasdiagRecurring
  module Monthly

    class HospitalSummaryJob < ApplicationJob

      def perform
        # settled_before = []
        settled_before = Note.where(key: "included-in-monthly-hospital-report", subject_type: "Measurement").pluck(:subject_id)
        date_start = 1.month.ago.at_beginning_of_month
        date_end = 1.month.ago.at_end_of_month
        # date_start = Time.now.at_beginning_of_month
        # date_end = Time.now.at_end_of_month
        last_month_authorized = []

        Institution.where(kind: "Hospital").all.each do |h|
          last_month_authorized << Measurement.includes(sample: {patient: :contractor}).where(Status: 5, AuthorizedAt: date_start..date_end).order(AuthorizedAt: :asc).where.not(Id: settled_before).where("Contractors.institution_id = ?", h.id).order("Contractors.institution_id ASC").pluck(:Id)
        end

        return if last_month_authorized.flatten.blank?
        MonthlyHospitalSummaryMailer.monthly_mail(last_month_authorized.flatten.uniq).deliver_later
      end
    	
    end

  end
end