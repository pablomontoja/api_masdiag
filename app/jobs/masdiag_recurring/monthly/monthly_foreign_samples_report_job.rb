class MonthlyForeignSamplesReportJob #< ApplicationJob
  include Delayed::RecurringJob
  run_every 1.month
  # run_at '02 07:45am' # ustawia drugiego dnia miesiąca
  run_at '01 04:45am'

  def perform  
    MonthlyForeignSamplesReportMailer.monthly_mail().deliver_later
  end
	
end