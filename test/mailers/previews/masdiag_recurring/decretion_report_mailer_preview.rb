class DecretionReportMailerPreview < ActionMailer::Preview
	
	def monthly_mail
		@message = []
		add_omega_samples()

		MasdiagRecurring::DecretionReportMailer.monthly_mail(@message)
	end

private

  def add_omega_table(samples)
    @message.push "<br>"
    @message.push "<hr>"
    @message.push "<b style='font-size: 13px; font-weight: bold;'>Kwasy OMEGA (tylko Diagnostyka Precyzyjna)</b>"
    @message.push "<hr>"
    @message.push "<table class='blueTable'>"

    @message.push "<tr>"
    @message.push "<th>"
    @message.push "Autoryzowane ogółem"
    @message.push "</th>"
    @message.push "<th>"
    @message.push "Autoryzowane w ostatnim miesiącu"
    @message.push "</th>"
    @message.push "<th>"
    @message.push "Kody próbek autoryzowane w ostatnim miesiącu"
    @message.push "</th>"
    @message.push "</tr>"

    samples.each do |smp|
      @message.push "<tr>"
      @message.push "<td>"
      @message.push smp.total
      @message.push "</td>"
      @message.push "<td>"
      @message.push smp.last_month
      @message.push "</td>"
      @message.push "<td>"
      @message.push smp.last_month_codes
      @message.push "</td>"
      @message.push "</tr>"
    end

    @message.push "</table>"
    @message.push "<hr>"
  end

  def add_omega_samples()
    date_start = (Time.now - 1.month).at_beginning_of_month
    date_end = (Time.now - 1.month).at_end_of_month
    total = Measurement.includes(sample: {patient: :contractor}).where(Status: 5, ProjectId: 21).where(sample: {patient: {Contractors: {institution_id: 33}}}).pluck(:SampleId).uniq.count
    last_month = Measurement.includes(sample: {patient: :contractor}).where(Status: 5, ProjectId: 21, AuthorizedAt: date_start..date_end).where(sample: {patient: {Contractors: {institution_id: 33}}}).pluck(:SampleId).uniq.count
    last_month_codes = Measurement.includes(sample: {patient: :contractor}).where(Status: 5, ProjectId: 21, AuthorizedAt: date_start..date_end).where(sample: {patient: {Contractors: {institution_id: 33}}}).pluck("sample.Code").uniq.join(", ")
    omega_samples = [ OpenStruct.new(total: total, last_month: last_month, last_month_codes: last_month_codes) ]
    add_omega_table(omega_samples)
  end
	
end