class MonthlyInstReportJob < ApplicationJob
  queue_as :default

  def perform(*args)
    codes_lekam = []
    codes_aqi = []

    samples_lekam = []
    samples_aqi = []

    date_start = (Time.now - 1.month).at_beginning_of_month
    date_end = (Time.now - 1.month).at_end_of_month

    # date_start = (Time.now - 1.month)
    # date_end = Time.now

    ####################################

    File.open("lekam2021-08.txt", "r").each_line do |line|
      code = line.strip.split(",")[0]
      codes_lekam.push(code)
    end


    Sample.where(Code: codes_lekam).where(AcceptanceDate: date_start..date_end).each do |sample|
      if sample != nil && sample.AcceptanceDate != nil
        samples_lekam.push("#{sample.Code}: #{sample.created_at}    ------ AcceptanceDate: #{sample.AcceptanceDate}")
      end
    end

    ####################################

    File.open("aqipharm.txt", "r").each_line do |line|
      code = line.strip.split(",")[0]
      codes_aqi.push(code)
    end


    Sample.where(Code: codes_aqi).each do |sample|
      if sample != nil
        samples_aqi.push("#{sample.Code}: #{sample.created_at}    ------ AcceptanceDate: #{sample.AcceptanceDate}")
      end
    end

    ####################################
    unreg_lekam = Sample.where(Code: codes_lekam, PatientId: 4798).count.to_s
    unreg_aqi = Sample.where(Code: codes_aqi, PatientId: 4798).count.to_s
    all_lekam = Sample.where(Code: codes_lekam).count.to_s


    puts "LEKAM\n"
    puts samples_lekam.join("\n").to_s
    puts "Wszystkie: #{samples_lekam.count.to_s}"
    puts "Niezarejestrowane: #{unreg_lekam}"
    puts "Wszystkie z tego zamówienia: #{all_lekam}"
    puts "\n"
    puts "AQI PHARM\n"
    puts samples_aqi.join("\n").to_s
    puts "Wszystkie: #{samples_aqi.count.to_s}"
    puts "Niezarejestrowane: #{unreg_aqi}"


  end
end
