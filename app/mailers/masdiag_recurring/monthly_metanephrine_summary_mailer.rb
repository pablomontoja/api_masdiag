class MonthlyMetanephrineSummaryMailer < ApplicationMailer
  require 'csv'
  default :template_path => "mailers/#{self.name.underscore}"

  def monthly_mail(samples) # samples should be an Array of Arrays (array of Code, AuthorizationAt and test name)
    attachments["metanefryny-#{Date.today.to_s(:db)}.csv"] = to_csv_file(samples).read

    mail(to: ['anna.grabowska@masdiag.pl','pawel.swider@masdiag.pl'], subject: 'Zestawienie próbek wykonanych w poprzednim miesiącu dla Szpitala Bielańskiego')
  end

private

  def to_csv_file(samples)
    header = "LP;Nazwa analizy;Kod próbki;Data wydania wyniku\n"

    io = StringIO.new("metanephrines")
    io << header

    samples.each_with_index do |smp, idx|
      io << "#{idx+1};#{smp[2]};#{smp[0]};#{smp[1]}\n"
    end

    io.rewind
    io
  end

end
