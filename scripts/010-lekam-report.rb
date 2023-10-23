require 'csv'

extracted_data = []

ReservedSampleCode.includes(package: :stock_room_item).where(InstitutionId: 32).in_batches(of: 100) do |relation|
	measurements = Measurement.includes(:sample).where(Samples: {Code: relation.pluck(:Code)})
	relation.each do |rsc|
		meases = measurements.where(Samples: {Code: rsc.Code})&.where&.not(Status: 7)&.any?  
		extracted_data << OpenStruct.new(code: rsc.Code, stock_out: rsc.package.stock_room_item.date_out, accept: rsc.sample&.AcceptanceDate, meases: meases, is_wrong: rsc.sample&.IsWrongRegistration)		
	end	
end

header = ["Kod","Magazyn OUT","Data przyjęcia","Czy wykonano pomiar?", "Czy wykonano rejestrację próbki?"]
file_name = "tmp/lekam-#{Date.today}-#{SecureRandom.uuid}.csv"

CSV.open(file_name, "w") do |csv|
  csv << header
  extracted_data.each do |rsc|
  	csv << [rsc.code, rsc.stock_out, rsc.accept, rsc.meases, !rsc.is_wrong]		  	
  end
end