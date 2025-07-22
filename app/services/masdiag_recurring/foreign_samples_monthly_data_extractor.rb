module MasdiagRecurring
	class ForeignSamplesMonthlyDataExtractor < ApplicationService
		attr_accessor :authorized, :measured, :canceled

		def initialize(projectId)
			@projectId = projectId
			@authorized = []
			@measured = []
			@canceled = []
			# @begin_date = Time.now.beginning_of_month
			# @end_date = Time.now.end_of_month
			@begin_date = 1.month.ago.beginning_of_month
			@end_date = 1.month.ago.end_of_month
		end

		def call
			begin
				cerascreen_finder()
				ga_finder()
				lalen_finder()
				lalen_eu_finder()
				amc_finder()
				luxbiotech_finder()
				physikit_finder()
				trime_finder()
				flat()

				handle_result(self)
			rescue Exception => e
				handle_error(e)
			end		
		end

	private

		def flat
			@authorized.flatten!
			@measured.flatten!
			@canceled.flatten!
		end

		def trime_finder
			samplesRegisteredIds = Sample.includes(patient: :contractor).where(RegistrationDate: 2.months.ago.beginning_of_month..@end_date).where(patient: {Contractors: {institution_id: 78}}).pluck(:Id)

			# project = Project.find @projectId

		  inproperProjectMeasurements = Measurement.includes(:result).where(SampleId: samplesRegisteredIds).where(Results: {ImportDate: @begin_date..@end_date}).where.not(ProjectId: @projectId).pluck(:Id)

			# autoryzowane
			authMeasurementsSampleIds = Measurement.includes(:result).where(ProjectId: @projectId).where(SampleId: samplesRegisteredIds).where.not(Id: inproperProjectMeasurements).where(Status: 5).where(Results: {ImportDate: @begin_date..@end_date}).pluck(:SampleId)
	  	
	  	codesWithSentCeraSamples = Result.includes(measurement: :sample).where(Measurements: {Status: 5, ProjectId: @projectId}).where(Measurements: {SampleId: authMeasurementsSampleIds}).order(ImportDate: :asc).pluck("Samples.Code,DATE_FORMAT(ImportDate,'%d-%m-%Y'),Samples.Code")

	  	@authorized << codesWithSentCeraSamples.map do |s|
				OpenStruct.new({type: :trime, sample_code: s[0], import_date: s[1], fname: s[2]})
			end	

	  	# zmierzone ale niezarejestrowane
	  	samplesMeasuredIds = []

	  	measuredMeasurements = []

	  	@measured << measuredMeasurements.map do |s|
				OpenStruct.new({type: :trime, sample_code: s[0], import_date: s[1], fname: s[2]})
			end	

	  	# anulowane próbki
	  	badQualitySamples = Measurement.includes(:sample).where(ProjectId: @projectId).where(Samples: {soaking_degree_id: [4, 5], CancellationDate: @begin_date..@end_date, Id: samplesRegisteredIds}).order("Samples.CancellationDate ASC").pluck("Samples.Code,DATE_FORMAT(Samples.CancellationDate,'%d-%m-%Y')")

	  	@canceled << badQualitySamples.map do |s|
				OpenStruct.new({type: :trime, sample_code: s[0], cancelation_date: s[1], fname: nil})
			end

		end

		def physikit_finder
			samplesRegisteredIds = Sample.includes(patient: :contractor).where(RegistrationDate: 2.months.ago.beginning_of_month..@end_date).where(patient: {Contractors: {institution_id: 73}}).pluck(:Id)

			# project = Project.find @projectId

		  inproperProjectMeasurements = Measurement.includes(:result).where(SampleId: samplesRegisteredIds).where(Results: {ImportDate: @begin_date..@end_date}).where.not(ProjectId: @projectId).pluck(:Id)

			# autoryzowane
			authMeasurementsSampleIds = Measurement.includes(:result).where(ProjectId: @projectId).where(SampleId: samplesRegisteredIds).where.not(Id: inproperProjectMeasurements).where(Status: 5).where(Results: {ImportDate: @begin_date..@end_date}).pluck(:SampleId)
	  	
	  	codesWithSentCeraSamples = Result.includes(measurement: :sample).where(Measurements: {Status: 5, ProjectId: @projectId}).where(Measurements: {SampleId: authMeasurementsSampleIds}).order(ImportDate: :asc).pluck("Samples.Code,DATE_FORMAT(ImportDate,'%d-%m-%Y'),Samples.Code")

	  	@authorized << codesWithSentCeraSamples.map do |s|
				OpenStruct.new({type: :physikit, sample_code: s[0], import_date: s[1], fname: s[2]})
			end	

	  	# zmierzone ale niezarejestrowane
	  	samplesMeasuredIds = []

	  	measuredMeasurements = []

	  	@measured << measuredMeasurements.map do |s|
				OpenStruct.new({type: :physikit, sample_code: s[0], import_date: s[1], fname: s[2]})
			end	

	  	# anulowane próbki
	  	badQualitySamples = []

	  	@canceled << badQualitySamples.map do |s|
				OpenStruct.new({type: :physikit, sample_code: s[0], cancelation_date: s[1], fname: s[2]})
			end

		end

		def lalen_finder
			au_codes = ReservedSampleCode.where(InstitutionId: 85).pluck(:Code)
			samplesRegisteredIds = Sample.includes(patient: :contractor).where(Code: au_codes).where(RegistrationDate: 2.months.ago.beginning_of_month..@end_date).pluck(:Id)

			# project = Project.find @projectId

		  inproperProjectMeasurements = Measurement.includes(:result).where(SampleId: samplesRegisteredIds).where(Results: {ImportDate: @begin_date..@end_date}).where.not(ProjectId: @projectId).pluck(:Id)

			# autoryzowane
			authMeasurementsSampleIds = Measurement.includes(:result).where(ProjectId: @projectId).where(SampleId: samplesRegisteredIds).where.not(Id: inproperProjectMeasurements).where(Status: 5).where(Results: {ImportDate: @begin_date..@end_date}).pluck(:SampleId)
	  	
	  	codesWithSentCeraSamples = Result.includes(measurement: :sample).where(Measurements: {Status: 5, ProjectId: @projectId}).where(Measurements: {SampleId: authMeasurementsSampleIds}).order(ImportDate: :asc).pluck("Samples.Code,DATE_FORMAT(ImportDate,'%d-%m-%Y'),Samples.Code,Measurements.ProjectId")

	  	@authorized << codesWithSentCeraSamples.map do |s|
	  		if s[3] == 10  			
	  			OpenStruct.new({type: :lalen, sample_code: s[0], import_date: s[1], fname: "vitaeq10"})
	  		else
	  			OpenStruct.new({type: :lalen, sample_code: s[0], import_date: s[1], fname: s[2]})
	  		end			
			end	

	  	# zmierzone ale niezarejestrowane
	  	samplesMeasuredIds = []

	  	measuredMeasurements = []

	  	@measured << measuredMeasurements.map do |s|
				if s[3] == 10  			
	  			OpenStruct.new({type: :lalen, sample_code: s[0], import_date: s[1], fname: "vitaeq10"})
	  		else
	  			OpenStruct.new({type: :lalen, sample_code: s[0], import_date: s[1], fname: s[2]})
	  		end	
			end	

	  	# anulowane próbki
	  	badQualitySamples = []

	  	@canceled << badQualitySamples.map do |s|
				OpenStruct.new({type: :lalen, sample_code: s[0], cancelation_date: s[1], fname: s[2]})
			end

		end

		def lalen_eu_finder
			eu_codes = ReservedSampleCode.where(InstitutionId: 89).pluck(:Code)
			samplesRegisteredIds = Sample.includes(patient: :contractor).where(Code: eu_codes).where(RegistrationDate: 2.months.ago.beginning_of_month..@end_date).pluck(:Id)

			# project = Project.find @projectId

		  inproperProjectMeasurements = Measurement.includes(:result).where(SampleId: samplesRegisteredIds).where(Results: {ImportDate: @begin_date..@end_date}).where.not(ProjectId: @projectId).pluck(:Id)

			# autoryzowane
			authMeasurementsSampleIds = Measurement.includes(:result).where(ProjectId: @projectId).where(SampleId: samplesRegisteredIds).where.not(Id: inproperProjectMeasurements).where(Status: 5).where(Results: {ImportDate: @begin_date..@end_date}).pluck(:SampleId)
	  	
	  	codesWithSentCeraSamples = Result.includes(measurement: :sample).where(Measurements: {Status: 5, ProjectId: @projectId}).where(Measurements: {SampleId: authMeasurementsSampleIds}).order(ImportDate: :asc).pluck("Samples.Code,DATE_FORMAT(ImportDate,'%d-%m-%Y'),Samples.Code,Samples.Code,Measurements.ProjectId")

	  	@authorized << codesWithSentCeraSamples.map do |s|
				if s[3] == 10  			
	  			OpenStruct.new({type: :lalen_eu, sample_code: s[0], import_date: s[1], fname: "vitaeq10"})
	  		else
	  			OpenStruct.new({type: :lalen_eu, sample_code: s[0], import_date: s[1], fname: s[2]})
	  		end	
			end	

	  	# zmierzone ale niezarejestrowane
	  	samplesMeasuredIds = []

	  	measuredMeasurements = []

	  	@measured << measuredMeasurements.map do |s|
				if s[3] == 10  			
	  			OpenStruct.new({type: :lalen_eu, sample_code: s[0], import_date: s[1], fname: "vitaeq10"})
	  		else
	  			OpenStruct.new({type: :lalen_eu, sample_code: s[0], import_date: s[1], fname: s[2]})
	  		end	
			end	

	  	# anulowane próbki
	  	badQualitySamples = []

	  	@canceled << badQualitySamples.map do |s|
				OpenStruct.new({type: :lalen_eu, sample_code: s[0], cancelation_date: s[1], fname: s[2]})
			end

		end

		def amc_finder
			samplesRegisteredIds = Sample.includes(patient: :contractor).where(RegistrationDate: 2.months.ago.beginning_of_month..@end_date).where(patient: {Contractors: {institution_id: 93}}).pluck(:Id)

			# project = Project.find @projectId

		  inproperProjectMeasurements = Measurement.includes(:result).where(SampleId: samplesRegisteredIds).where(Results: {ImportDate: @begin_date..@end_date}).where.not(ProjectId: @projectId).pluck(:Id)

			# autoryzowane
			authMeasurementsSampleIds = Measurement.includes(:result).where(ProjectId: @projectId).where(SampleId: samplesRegisteredIds).where.not(Id: inproperProjectMeasurements).where(Status: 5).where(Results: {ImportDate: @begin_date..@end_date}).pluck(:SampleId)
	  	
	  	codesWithSentCeraSamples = Result.includes(measurement: :sample).where(Measurements: {Status: 5, ProjectId: @projectId}).where(Measurements: {SampleId: authMeasurementsSampleIds}).order(ImportDate: :asc).pluck("Samples.Code,DATE_FORMAT(ImportDate,'%d-%m-%Y'),Samples.Code,Samples.Code,Measurements.ProjectId")

	  	@authorized << codesWithSentCeraSamples.map do |s|
				if s[3] == 10  			
	  			OpenStruct.new({type: :amc, sample_code: s[0], import_date: s[1], fname: "vitaeq10"})
	  		else
	  			OpenStruct.new({type: :amc, sample_code: s[0], import_date: s[1], fname: s[2]})
	  		end
			end	

	  	# zmierzone ale niezarejestrowane
	  	samplesMeasuredIds = []

	  	measuredMeasurements = []

	  	@measured << measuredMeasurements.map do |s|
				if s[3] == 10  			
	  			OpenStruct.new({type: :amc, sample_code: s[0], import_date: s[1], fname: "vitaeq10"})
	  		else
	  			OpenStruct.new({type: :amc, sample_code: s[0], import_date: s[1], fname: s[2]})
	  		end
			end	

	  	# anulowane próbki
	  	badQualitySamples = []

	  	@canceled << badQualitySamples.map do |s|
				OpenStruct.new({type: :amc, sample_code: s[0], cancelation_date: s[1], fname: s[2]})
			end

		end

		def luxbiotech_finder
			samplesRegisteredIds = Sample.includes(patient: :contractor).where(RegistrationDate: 2.months.ago.beginning_of_month..@end_date).where(patient: {Contractors: {institution_id: 95}}).pluck(:Id)

			# project = Project.find @projectId

		  inproperProjectMeasurements = Measurement.includes(:result).where(SampleId: samplesRegisteredIds).where(Results: {ImportDate: @begin_date..@end_date}).where.not(ProjectId: @projectId).pluck(:Id)

			# autoryzowane
			authMeasurementsSampleIds = Measurement.includes(:result).where(ProjectId: @projectId).where(SampleId: samplesRegisteredIds).where.not(Id: inproperProjectMeasurements).where(Status: 5).where(Results: {ImportDate: @begin_date..@end_date}).pluck(:SampleId)
	  	
	  	codesWithSentCeraSamples = Result.includes(measurement: :sample).where(Measurements: {Status: 5, ProjectId: @projectId}).where(Measurements: {SampleId: authMeasurementsSampleIds}).order(ImportDate: :asc).pluck("Samples.Code,DATE_FORMAT(ImportDate,'%d-%m-%Y'),Samples.Code,Samples.Code,Measurements.ProjectId")

	  	@authorized << codesWithSentCeraSamples.map do |s|
				if s[3] == 10  			
	  			OpenStruct.new({type: :luxbiotech, sample_code: s[0], import_date: s[1], fname: "vitaeq10"})
	  		else
	  			OpenStruct.new({type: :luxbiotech, sample_code: s[0], import_date: s[1], fname: s[2]})
	  		end	
			end	

	  	# zmierzone ale niezarejestrowane
	  	samplesMeasuredIds = []

	  	measuredMeasurements = []

	  	@measured << measuredMeasurements.map do |s|
				if s[3] == 10  			
	  			OpenStruct.new({type: :luxbiotech, sample_code: s[0], import_date: s[1], fname: "vitaeq10"})
	  		else
	  			OpenStruct.new({type: :luxbiotech, sample_code: s[0], import_date: s[1], fname: s[2]})
	  		end	
			end	

	  	# anulowane próbki
	  	badQualitySamples = []

	  	@canceled << badQualitySamples.map do |s|
				OpenStruct.new({type: :luxbiotech, sample_code: s[0], cancelation_date: s[1], fname: s[2]})
			end

		end

		def ga_finder
			samplesSentIds = GaSample.where(ResultSentDate: 2.months.ago.beginning_of_month..@end_date).where(MasdiagProjectId: @projectId).where(IsResultSent: true).pluck(:SampleId)

			# project = Project.find @projectId

		  inproperProjectMeasurements = Measurement.includes(:result).where(SampleId: samplesSentIds).where(Results: {ImportDate: @begin_date..@end_date}).where.not(ProjectId: @projectId).pluck(:Id)
		  samplesCountedInPreviousMonth = Measurement.includes(:result).where(SampleId: samplesSentIds).where(Results: {ImportDate: 2.months.ago.beginning_of_month..2.months.ago.end_of_month}).where(ProjectId: @projectId).pluck(:SampleId)

			# autoryzowane i wysłane
			authMeasurementsSampleIds = Measurement.includes(:result).where(ProjectId: @projectId).where(SampleId: samplesSentIds).where.not(Id: inproperProjectMeasurements).where.not(SampleId: samplesCountedInPreviousMonth).where(Status: 5).where(Results: {ImportDate: @begin_date..@end_date}).pluck(:SampleId)
	  	
	  	codesWithSentCeraSamples = Result.includes(measurement: {sample: :ga_sample}).where(Measurements: {Status: 5, ProjectId: @projectId}).where(Measurements: {SampleId: authMeasurementsSampleIds}).order(ImportDate: :asc).pluck("Samples.Code,DATE_FORMAT(ImportDate,'%d-%m-%Y'),GaSamples.Type")

	  	@authorized << codesWithSentCeraSamples.map do |s|
				OpenStruct.new({type: :ga, sample_code: s[0], import_date: s[1], fname: s[2]})
			end	

	  	# zmierzone ale niezarejestrowane
	  	samplesMeasuredIds = GaSample.where(IsResultSent: false, MasdiagProjectId: @projectId).or(GaSample.where(IsResultSent: true, ResultSentDate: @end_date..Time.now, MasdiagProjectId: @projectId)).pluck(:SampleId)

	  	measuredMeasurements = Measurement.includes(:result, sample: :ga_sample).where(SampleId: samplesMeasuredIds, ProjectId: @projectId, Status: [4, 5])
	  													.where.not(Id: inproperProjectMeasurements).where(Results: {ImportDate: @begin_date..@end_date}).order("Results.ImportDate ASC").pluck("Samples.Code,DATE_FORMAT(Results.ImportDate,'%d-%m-%Y'),GaSamples.Type")

	  	@measured << measuredMeasurements.map do |s|
				OpenStruct.new({type: :ga, sample_code: s[0], import_date: s[1], fname: s[2]})
			end	

	  	# anulowane próbki
	  	badQualitySamples = GaSample.includes(:sample).where(MasdiagProjectId: @projectId, BadQuality: true, ResultSentDate: @begin_date..@end_date).where.not(ResultSentDate: nil).order(ResultSentDate: :asc).pluck("Samples.Code,DATE_FORMAT(ResultSentDate,'%d-%m-%Y'),Type")

	  	@canceled << badQualitySamples.map do |s|
				OpenStruct.new({type: :ga, sample_code: s[0], cancelation_date: s[1], fname: s[2]})
			end			
		end

		def cerascreen_finder
			samplesSentIds = CeraSample.where(ResultSentToCeraDate: 1.months.ago.beginning_of_month..@end_date).where(MasdiagProjectId: @projectId).where(IsResultSentToCera: true).pluck(:SampleId)

			# project = Project.find @projectId

		  inproperProjectMeasurements = Measurement.includes(:result).where(SampleId: samplesSentIds).where(Results: {ImportDate: @begin_date..@end_date}).where.not(ProjectId: @projectId).pluck(:Id)
		  samplesCountedInPreviousMonth = Measurement.includes(:result).where(SampleId: samplesSentIds).where(Results: {ImportDate: 2.months.ago.beginning_of_month..2.months.ago.end_of_month}).where(ProjectId: @projectId).pluck(:SampleId)

			# autoryzowane i wysłane
			authMeasurementsSampleIds = Measurement.includes(:result).where(ProjectId: @projectId).where(SampleId: samplesSentIds).where.not(Id: inproperProjectMeasurements).where.not(SampleId: samplesCountedInPreviousMonth).where(Status: 5).where(Results: {ImportDate: @begin_date..@end_date}).pluck(:SampleId)
	  	
	  	# codesWithSentCeraSamples = Result.includes(measurement: :sample).where(Measurements: {Status: 5, ProjectId: @projectId}).where(Measurements: {SampleId: authMeasurementsSampleIds}).order(ImportDate: :asc).pluck("Samples.Code,DATE_FORMAT(ImportDate,'%d-%m-%Y')")

	  	codesWithSentCeraSamples = Result.includes(measurement: {sample: :cera_sample}).where(Measurements: {Status: 5, ProjectId: @projectId}).where(Measurements: {SampleId: authMeasurementsSampleIds}).order(ImportDate: :asc).pluck("Samples.Code,DATE_FORMAT(ImportDate,'%d-%m-%Y'),CeraSamples.CeraType")

	  	@authorized << codesWithSentCeraSamples.map do |s|
				OpenStruct.new({type: :cerascreen, sample_code: s[0], import_date: s[1], fname: s[2]})
			end	

	  	# zmierzone ale niezarejestrowane
	  	samplesMeasuredIds = CeraSample.where(IsResultSentToCera: false, MasdiagProjectId: @projectId).or(CeraSample.where(IsResultSentToCera: true, ResultSentToCeraDate: @end_date..Time.now, MasdiagProjectId: @projectId)).pluck(:SampleId)

	  	measuredMeasurements = Measurement.includes(:result, sample: :cera_sample).where(SampleId: samplesMeasuredIds, ProjectId: @projectId, Status: [4, 5]).where.not(Id: inproperProjectMeasurements).where(Results: {ImportDate: @begin_date..@end_date}).order("Results.ImportDate ASC").pluck("Samples.Code,DATE_FORMAT(Results.ImportDate,'%d-%m-%Y'),CeraSamples.CeraType")

	  	@measured << measuredMeasurements.map do |s|
				OpenStruct.new({type: :cerascreen, sample_code: s[0], import_date: s[1], fname: s[2]})
			end	

	  	# anulowane próbki
	  	badQualitySamples = CeraSample.includes(:sample).where(MasdiagProjectId: @projectId, BadQuality: true, ResultSentToCeraDate: @begin_date..@end_date).where.not(ResultSentToCeraDate: nil).order(ResultSentToCeraDate: :asc).pluck("Samples.Code,DATE_FORMAT(ResultSentToCeraDate,'%d-%m-%Y'),CeraType")

	  	@canceled << badQualitySamples.map do |s|
				OpenStruct.new({type: :cerascreen, sample_code: s[0], cancelation_date: s[1], fname: s[2]})
			end			
		end

		def handle_result(result = nil)
			OpenStruct.new({success?: true, payload: result})
		end

		def handle_error(error)
	    OpenStruct.new({success?: false, error: error})
	  end
	end

end