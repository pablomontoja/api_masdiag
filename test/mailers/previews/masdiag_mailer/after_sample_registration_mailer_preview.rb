module MasdiagMailer
	class AfterSampleRegistrationMailerPreview < ActionMailer::Preview
		
		def regular_sample
			sample_id = Measurement.includes(:sample).where.not(ProjectId: [1, 15, 16, 17, 25, 29, 32]).where(Status: 1).where.not(sample: { PatientId: nil }).limit(100).pluck(:SampleId).sample
			MasdiagMailer::IndMailer.after_sample_registration(sample_id)
		end

		def three_methyl_dopa
			sample_id = Measurement.includes(:sample).where(ProjectId: 25).where.not(sample: { PatientId: nil }).limit(100).pluck(:SampleId).sample
			MasdiagMailer::ThreeMethylDopaMailer.after_sample_registration(sample_id)
		end
		
	end
end