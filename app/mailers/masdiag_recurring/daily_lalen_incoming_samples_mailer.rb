class DailyLalenIncomingSamplesMailer < ApplicationMailer
  require 'csv'
  default :template_path => "mailers/#{self.name.underscore}"
  after_action :add_notes
  SummarySample = Struct.new(:code, :accept_date, :business_name, :qns)

  def daily_mail(sample_ids) # sample_ids should be an Array of sample ids
    summary_samples = []
    @samples = Sample.where(Id: sample_ids).all
    @samples.map do |smp|
      summary_samples << SummarySample.new(smp.Code, smp.AcceptanceDate.strftime("%F"), smp.rsc.institution.name, qns(smp))
    end

    csv_file_path = "tmp/#{SecureRandom.uuid}.csv"
    gen_csv_file(summary_samples, csv_file_path)
    attachments["incoming-eu-samples-#{Date.today.to_s(:db)}.csv"] = File.read(csv_file_path)

    mail(to: 'lalen.dogan@masdiag.pl', bcc: 'pawel.swider@masdiag.pl', subject: 'Masdiag Lab - EU Incoming Samples')
  end

private

  def gen_csv_file(summary_samples, csv_file_path)
    CSV.open(csv_file_path, "w", col_sep: ";") do |csv|
      config = ["sep=;"]
      header = ["Receive Date", "Sample ID", "Business name", "QNS"]
      
      csv << config
      csv << header
      summary_samples.each do |smp|
        csv << ["#{smp.accept_date}", "#{smp.code}", "#{smp.business_name}", "#{smp.qns}"]
      end

    end
  end

  def qns(sample)
    result = ''
    result = "QNS" if sample.SampleStatus == 4 || [4, 5].include?(sample.soaking_degree_id)
    result
  end


  def add_notes()
    @samples.each do |smp|
      Note.create(key: "lalen-eu-incoming-samples-email", subject: smp, description: "Zestawienie przyjętych próbek dla Lalen EU, plik CSV z dnia #{Time.now.strftime("%F")}")
    end
  end

end

# Receive Date  Sample ID