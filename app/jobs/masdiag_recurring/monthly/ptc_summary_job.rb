module MasdiagRecurring
  module Monthly

    class PtcSummaryJob < ApplicationJob

      def perform
        # settled_before = []
        settled_before = Note.where(key: "included-in-monthly-ptc-report", subject_type: "Measurement").pluck(:subject_id)
        date_start = (Time.now - 1.month).at_beginning_of_month
        date_start = (Time.now - 12.month).at_beginning_of_month if settled_before.blank?
        date_end = (Time.now - 1.month).at_end_of_month

        demo_codes = %w(F86D3 H2LS8 WMEVR E4WXD NSKVQ C7FTF EWCDC IM1AD K3G9W M3DY4)
        ptc_codes = ReservedSampleCode.where(InstitutionId: 91).pluck(:Code)
        ptc_last_month_authorized = []
        ptc_last_month_authorized = Measurement.includes(sample: {patient: :contractor}).where(ProjectId: 25, Status: 5, AuthorizedAt: date_start..date_end).order(AuthorizedAt: :asc).where.not(Id: settled_before).where(sample: {Code: ptc_codes}).where.not(sample: {Code: demo_codes}).pluck(:Id)

        rest_institutions_last_month_authorized = Measurement.includes(sample: {patient: :contractor}).where(ProjectId: 25, Status: 5).where.not(Id: settled_before).where.not(sample: {patient: {Contractors: {institution_id: 91}}}).where.not(sample: {Code: ptc_codes}).where.not(sample: {Code: demo_codes}).order("Contractors.institution_id ASC").pluck(:Id)

        return if ptc_last_month_authorized.flatten.blank? && rest_institutions_last_month_authorized.flatten.blank?

        MonthlyPtcSummaryMailer.monthly_mail(ptc_last_month_authorized.flatten.uniq, rest_institutions_last_month_authorized.flatten.uniq).deliver_later
      end
    	
    end
  end
end