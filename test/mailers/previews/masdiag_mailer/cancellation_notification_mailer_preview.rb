class CancellationNotificationMailerPreview < ActionMailer::Preview

	def send_mail_to_patient
		cancelled = Sample.includes(:patient).where(soaking_degree_id: [4, 5]).where(Patients: {IsVirtual: false}).where.not(Patients: {email: nil}).limit(1000).pluck(:Code)
		rsc_boxes = ReservedSampleCode.includes(package: :product).where(Code: cancelled).where(package: {products: {type: [1, 4]}}).where(IsRetailSale: true).limit(100).pluck(:Code)
		sample = Sample.includes(:patient).where(Code: rsc_boxes).where(soaking_degree_id: [4, 5]).where(Patients: {IsVirtual: false}).where.not(Patients: {email: nil}).limit(10).sample

		MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient(sample.Id)	
	end

	def send_mail_to_contractor
		cancelled = Sample.includes(:patient).where(soaking_degree_id: [4, 5]).where(Patients: {IsVirtual: false}).where.not(Patients: {email: nil}).limit(1000).pluck(:Code)
		not_rsc_boxes = ReservedSampleCode.includes(package: :product).where(Code: cancelled).where.not(package: {products: {type: [1, 4]}}).limit(100).pluck(:Code)
		sample = Sample.includes(:patient).where(Code: not_rsc_boxes).where(soaking_degree_id: [4, 5]).where(Patients: {IsVirtual: false}).where.not(Patients: {email: nil}).limit(10).sample
    contractor = Contractor.find(sample.patient.ContractorId)
    MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_contractor(sample.Id, contractor.email)
	end

	def standard_cancellation_notification
		cancelled = Sample.includes(:patient).where(soaking_degree_id: [4, 5]).where(Patients: {IsVirtual: false}).where.not(Patients: {email: nil}).limit(1000).pluck(:Code)
		rsc_boxes = ReservedSampleCode.includes(package: :product).where(Code: cancelled, InstitutionId: 32).where(package: {products: {type: [1, 4]}}).where(IsRetailSale: true).limit(100).pluck(:Code)
		sample = Sample.includes(:patient).where(Code: rsc_boxes).where(soaking_degree_id: [4, 5]).where(Patients: {IsVirtual: false}).where.not(Patients: {email: nil}).limit(10).sample
		MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample.Id)		
	end

	
end