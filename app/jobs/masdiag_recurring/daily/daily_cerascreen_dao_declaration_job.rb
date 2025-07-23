class DailyCerascreenDaoDeclarationJob #< ApplicationJob
  include Delayed::RecurringJob
  run_every 1.day
  run_at '08:00pm'

  def perform
    settled_before = Note.where(key: "cerascreen-dao-declaration-email", subject_type: "ReservedSampleCode").pluck(:subject_id)
    today_rsc_ids = ReservedTest.includes(:reserved_sample_code).where.not(reserved_sample_code_id: settled_before).where(project_id: 24).pluck(:reserved_sample_code_id)

    return if today_rsc_ids.flatten.blank?
    DailyCerascreenDaoDeclarationMailer.daily_mail(today_rsc_ids.flatten).deliver_later
  end
	
end