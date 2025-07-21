class MonthlyMetanephrineSummaryJob #< ApplicationJob
  include Delayed::RecurringJob
  run_every 1.month
  # run_at '02 07:45am' # ustawia drugiego dnia miesiąca
  run_at '01 04:50am'

  def perform
    settled_before = KeyValueDbStore.metanephrine_settled_samples
    date_start = (Time.now - 1.month).at_beginning_of_month
    date_end = (Time.now - 1.month).at_end_of_month
    # date_start = Time.now.at_beginning_of_month
    # date_end = Time.now.at_end_of_month

    # last_month_authorized = Measurement.includes(:sample).includes(:project).where(Status: 5, AuthorizedAt: date_start..date_end, ProjectId: 20).order(AuthorizedAt: :asc).where.not(Samples: {Code: settled_before}).pluck("Samples.Code", :AuthorizedAt, "Projects.Name").map{|lma| [lma[0], lma[1].strftime("%d.%m.%Y"), lma[2]]}
    last_month_authorized = Measurement.includes(sample: {patient: :contractor}).includes(:project).where(Status: 5, AuthorizedAt: date_start..date_end).order(AuthorizedAt: :asc).where.not(Id: settled_before).where("Contractors.institution_id = 69").pluck("Samples.Code", :AuthorizedAt, "Projects.Name", :Id).map{|lma| [lma[0], lma[1].strftime("%d.%m.%Y"), lma[2], lma[3]]}

    return if last_month_authorized.blank?

    MonthlyMetanephrineSummaryMailer.monthly_mail(last_month_authorized).deliver_later
    KeyValueDbStore.metanephrine_settled_samples = (settled_before + last_month_authorized.map{|s| s[3]}).uniq
  end
	
end