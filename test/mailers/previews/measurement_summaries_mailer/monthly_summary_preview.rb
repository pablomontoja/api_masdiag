class MonthlySummaryPreview < ActionMailer::Preview

  def monthly_summary
  	MeasurementSummariesMailer.monthly_summary(10)
  end

end