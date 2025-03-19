class AfterSampleRegistrationMailerPreview < ActionMailer::Preview
	
	def regular_sample
		sample_id = Measurement.where.not(ProjectId: [1, 25]).where(Status: 1).limit(100).pluck(:SampleId).sample
		MasdiagMailer::IndMailer.after_sample_registration(sample_id)
	end

	def three_methyl_dopa
		sample_id = Measurement.where(ProjectId: 25, Status: 1).limit(100).pluck(:SampleId).sample
		MasdiagMailer::ThreeMethylDopaMailer.after_sample_registration(sample_id)
	end
	
end