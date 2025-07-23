class DailyLalenIncomingSamplesJob #< ApplicationJob
  include Delayed::RecurringJob
  run_every 1.day
  run_at '05:00pm'

  def perform
    settled_before = Note.where(key: "lalen-eu-incoming-samples-email", subject_type: "Sample").pluck(:subject_id)
    today_accepted_sample_ids = Sample.includes({patient: :contractor}).where.not(AcceptanceDate: nil, Id: settled_before).where("Contractors.institution_id = ?", 89).pluck(:Id)

    return if today_accepted_sample_ids.flatten.blank?
    DailyLalenIncomingSamplesMailer.daily_mail(today_accepted_sample_ids).deliver_later
  end
	
end