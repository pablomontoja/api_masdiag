module MasdiagMailer
	class RscNotAssignedMailerPreview < ActionMailer::Preview

		def alert_email
			codes = Sample.where("LENGTH(Code)!=6").limit(1000).pluck(:Code)
			rsc = ReservedSampleCode.where(
																Code: codes
															)
			                        .where.not(
															  Id: ReservedTest.select(:reserved_sample_code_id)
															).to_a.sample
			MasdiagMailer::RscNotAssignedMailer.send_mail(rsc)
		end

	end
end