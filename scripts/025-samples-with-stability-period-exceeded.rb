
Sample.includes(patient: :contractor).where(patient: { contractor: { institution_id: V1::Common::LALEN_INSTITUTION_IDS }}).where("DATEDIFF(AcceptanceDate,sample_collection_date) > ?", 56).where.not("LENGTH(Code)=6").order(Id: :desc).limit(10).pluck(:Code)


codes = Sample.includes(patient: :contractor).where(patient: { Contractors: { institution_id: V1::Common::LALEN_INSTITUTION_IDS }}).where("DATEDIFF(AcceptanceDate,sample_collection_date) > ?", 56).where.not("LENGTH(Code)=6").where(AcceptanceDate: 6.months.ago..nil).order(Id: :desc).pluck(:Code)

puts "Code|Institution name|sample_collection_date|sample arrival date|Patient BirthDate"

codes.each do |code|
rsc = ReservedSampleCode.find_by(Code: code)
puts "#{rsc.Code}|#{rsc.institution.name}|#{rsc.sample.sample_collection_date}|#{rsc.sample.AcceptanceDate}|#{rsc.sample.patient.BirthDate}"
end






Sample.includes(patient: :contractor).where(patient: { Contractors: { institution_id: V1::Common::LALEN_INSTITUTION_IDS }}).where("sample_collection_date > ?", 2.months.ago).where(AcceptanceDate: nil).where.not("LENGTH(Code)=6").order(Id: :desc).limit(10).pluck(:Code)