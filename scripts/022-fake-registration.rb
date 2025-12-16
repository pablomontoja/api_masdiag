def sample_params(params)
  params.require(:sample).permit(:id, :code, :sample_collection_date, patient_attributes: [:first_name, :last_name, :email, :pesel, :contractor_id, :birth_date, :gender, :id_document, :id_number, :language]).each_value do |value|
    case value
    when String
      value.try(:strip!)
    when ActionController::Parameters
      value.each_value { |value| value.try(:strip!) }
    end
  end
end

codes = %w[EUAC104241 EUAC104392 EUAC108522 EUKZITDT EUVEMABL EUAC407260 EUETFULG EUAC108581 EUAC108570 EUAC110946 EU3PZACN EUAC108614 EUAC105081 EUJWE8KQ EU32BQUW EUAC104230]

Sample.where(PatientId: 4798, Code: codes).each do |sample|
	params = ActionController::Parameters.new({"sample"=>{"code"=>sample.Code, "sample_collection_date"=>2.weeks.ago, "patient_attributes"=>{"first_name"=>"Fake", "last_name"=>"Patient", "birth_date"=>"2000-01-01", "gender"=>0, "email"=>"fake.patient@masdiag.pl"}}})
	s = V1::WrongSampleUpdater.call(sample, sample_params(params), sample.rsc)
	s.validate
	if s.save!(context: :fv1)
		puts "#{sample.Code} SAVED"
    ::LalenApi::RegisterKitJob.perform_later(sample) if V1::Common::LALEN_INSTITUTION_IDS.include?(sample.patient&.contractor&.institution_id)
  end
end

    