module MasdiagRecurring
	class CeraStatisticCreator < ApplicationService
		require 'csv'
		require 'securerandom'
		attr_reader :project_id
		attr_reader :db_data

		CeraSampleItem = Struct.new(:sample_id, :acceptance_date, :result_sent_to_cera_date, :working_days) # LastTwoMonthCeraSamples
		RejectedCeraSample = Struct.new(:sample_id, :result_sent_to_cera_date)
		AcceptedSample = Struct.new(:sample_id, :acceptance_date)
		DelayedRegistrationSample = Struct.new(:sample_id, :acceptance_date)

		def initialize(project_id)
			@project_id = project_id
		end

		def call
			begin
				items = cera_items()
				rejected = rejected_items()
				accepted = accepted_items()
				delayed = delayed_registration_items()
				not_registered = not_registered_items()
				@db_data = OpenStruct.new({items: items, rejected: rejected, accepted: accepted_items, delayed: delayed, not_registered: not_registered})
				markers = prepare_cera_perf_markers()

				handle_result( to_csv_file(markers) )
			rescue StandardError => e
				Sentry.capture_exception(e)
				handle_error(e)
			end		
		end

	private

		def handle_result(result = nil)
			OpenStruct.new({success?: true, payload: result})
		end

		def handle_error(error)
	    OpenStruct.new({success?: false, error: error})
	  end

	  def cera_items
	  	twoMonthsAgo = DateTime.now.days_ago(61)
			cera_sample_items = []
			items = CeraSample.includes(:sample)
												.where("ResultSentToCeraDate > ?", twoMonthsAgo)
												.where(IsResultSentToCera: true, MasdiagProjectId: @project_id, BadQuality: false, Samples: {WasWrongRegistration: false})
												.pluck('SampleId, Samples.AcceptanceDate, ResultSentToCeraDate')

			cera_sample_items = items.map do |item|
				CeraSampleItem.new(item[0], item[1], item[2], item[1].to_datetime.at_beginning_of_day.business_days_until(item[2].at_beginning_of_day))
			end
	  end

	  def rejected_items
	  	twoMonthsAgo = DateTime.now.days_ago(61)
			cera_sample_items = []
			items = CeraSample.includes(:sample)
												.where("ResultSentToCeraDate > ?", twoMonthsAgo)
												.where(IsResultSentToCera: true, MasdiagProjectId: @project_id, BadQuality: true, Samples: {WasWrongRegistration: false})
												.select([:SampleId, :ResultSentToCeraDate])

			cera_sample_items = items.map do |item|
				RejectedCeraSample.new(item.SampleId, item.ResultSentToCeraDate)
			end		
	  end

	  def accepted_items
	  	twoMonthsAgo = DateTime.now.days_ago(61)
			cera_sample_items = []
			items = CeraSample.includes(:sample)
												.where("Samples.AcceptanceDate > ?", twoMonthsAgo)
												.where(MasdiagProjectId: @project_id, BadQuality: false, Samples: {WasWrongRegistration: false})
												.select([:SampleId, :"Samples.AcceptanceDate"])

			cera_sample_items = items.map do |item|
				AcceptedSample.new(item.SampleId, item.sample.AcceptanceDate)
			end		
	  end

	  def delayed_registration_items
	  	twoMonthsAgo = DateTime.now.days_ago(61)
			cera_sample_items = []
			items = CeraSample.includes(:sample)
												.where("Samples.AcceptanceDate > ?", twoMonthsAgo)
												.where(IsResultSentToCera: true, MasdiagProjectId: @project_id, BadQuality: false, Samples: {WasWrongRegistration: true})
												.select([:SampleId, :"Samples.AcceptanceDate"])

			cera_sample_items = items.map do |item|
				DelayedRegistrationSample.new(item.SampleId, item.sample.AcceptanceDate)
			end
	  end

	  def not_registered_items
	  	twoMonthsAgo = DateTime.now.days_ago(61)
			items = CeraSample.includes(:sample)
												.where("Samples.AcceptanceDate > ?", twoMonthsAgo)
												.where(MasdiagProjectId: @project_id, BadQuality: false, Samples: {IsWrongRegistration: true})
												.count
			items
	  end

	  def prepare_cera_perf_markers
	  	markers = []

	  	(DateTime.now.days_ago(61)..DateTime.now).each do |date|
	  		start_of_day = date.at_beginning_of_day
			  end_of_day = date.at_end_of_day

			  all_sent_results_count = @db_data.items.select {|c| c.result_sent_to_cera_date > start_of_day && c.result_sent_to_cera_date < end_of_day }.size
			  # puts all_sent_results_count

			  if all_sent_results_count == 0
				  markers.push(
				  	OpenStruct.new({
				  		day: start_of_day,
				  		all_sent_results: all_sent_results_count,
				  		accepted_samples: @db_data.accepted.select {|c| c.acceptance_date > start_of_day && c.acceptance_date < end_of_day }.size,
				  		rejected_samples: @db_data.rejected.select {|c| c.result_sent_to_cera_date > start_of_day && c.result_sent_to_cera_date < end_of_day }.size,
				  		delayed_registration_samples: @db_data.delayed.select {|c| c.acceptance_date > start_of_day && c.acceptance_date < end_of_day }.size,
				  		not_registered: @db_data.not_registered,
				  		sent_grouped_by_days: {},
				  	})
				  )
				  next
			  end

			  sentAtCurrentDay = @db_data.items.select {|c| c.result_sent_to_cera_date > start_of_day && c.result_sent_to_cera_date < end_of_day }
			  grouped_by_working_day = sentAtCurrentDay.group_by{|c| c.working_days}
			  
			  sent_by_days = Hash.new
			  sent_by_days[1] = sentAtCurrentDay.select{|c| c.working_days < 2}.size

			  (2..4).to_a.map do |s|		  	
			  	if grouped_by_working_day.has_key?(s)
			  		sent_by_days[s] = grouped_by_working_day.fetch(s).length
					else
						sent_by_days[s] = 0
					end				 	
			  end

			  sent_by_days[5] = sentAtCurrentDay.select{|c| c.working_days > 4}.size

			  # puts sent_grouped_by_days.class

			  markers.push(
			  	OpenStruct.new({
			  		day: start_of_day,
			  		all_sent_results: all_sent_results_count,
			  		accepted_samples: @db_data.accepted.select {|c| c.acceptance_date > start_of_day && c.acceptance_date < end_of_day }.size,
			  		rejected_samples: @db_data.rejected.select {|c| c.result_sent_to_cera_date > start_of_day && c.result_sent_to_cera_date < end_of_day }.size,
			  		delayed_registration_samples: @db_data.delayed.select {|c| c.acceptance_date > start_of_day && c.acceptance_date < end_of_day }.size,
			  		not_registered: @db_data.not_registered,
			  		sent_grouped_by_days: sent_by_days,
			  	})
			  )
			  # puts sentAtCurrentDay

			  
			end
			markers
	  end

	  def to_csv_string(markers)
	  	header = ["Day","AllSentResults","SentInD1","SentInD2","SentInD3","SentInD4","SentInD5+","AcceptedSamples","RejectedSamples", "NotRegisteredAtAcceptanceDate"]

	  	csv_string = CSV.generate do |csv|
			  csv << header
			  markers.each do |m|
			  	sent_in_days = (1..5).to_a.map do |s|
			  		result = 0
			  		result = m.sent_grouped_by_days.fetch(s) if m.sent_grouped_by_days.has_key?(s)
			  		result = 0 unless m.sent_grouped_by_days.has_key?(s)
			  		result
			  	end

			  	csv << [m.day, m.all_sent_results] + sent_in_days + [m.accepted_samples, m.rejected_samples, m.delayed_registration_samples]		  	
			  end		

			  csv << ["Nadal niezarejestrowane:", "#{markers.last.not_registered}"]  
			end
			csv_string
	  end

	  def to_csv_file(markers)
	  	header = ["Day","AllSentResults","SentInD1","SentInD2","SentInD3","SentInD4","SentInD5","AcceptedSamples","RejectedSamples", "NotRegisteredAtAcceptanceDate"]
	  	file_name = "tmp/cerascreen-#{Date.today}-#{SecureRandom.uuid}.csv"
	  	
	  	CSV.open(file_name, "w") do |csv|
			  csv << header
			  markers.each do |m|
			  	sent_in_days = (1..5).to_a.map do |s|
			  		result = 0
			  		result = m.sent_grouped_by_days.fetch(s) if m.sent_grouped_by_days.has_key?(s)
			  		result = 0 unless m.sent_grouped_by_days.has_key?(s)
			  		result
			  	end

			  	csv << [m.day, m.all_sent_results] + sent_in_days + [m.accepted_samples, m.rejected_samples, m.delayed_registration_samples]		  	
			  end

			  csv << ["Nadal niezarejestrowane:", markers.last.not_registered]
			  results_not_sent = CeraSample.includes(:sample).where(MasdiagProjectId: 2, BadQuality: false, IsResultSentToCera: false,  Samples: {IsWrongRegistration: false}).where.not(CeraType: nil, PatientId: 2209).where("Samples.AcceptanceDate > ?", 3.months.ago).where("CheckupJson NOT LIKE '%-- blad: invalid_request_data -- opis: The submitted request data is incomplete or invalid%'").size
			  csv << ["Nie wysłano jeszcze wyniku:", results_not_sent.to_s]  
			end

			file_name
	  end

	end
end