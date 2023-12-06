# analytes = Analyte.where(Id: [80, 82, 84, 85, 86])

# analytes.each do |an|
# 	newAn = an.dup
# 	newAn.ProjectId = 22
# 	newAn.save

# 	an.analyte_ranges.each do |ar|
# 		newAr = ar.dup
# 		newAr.AnalyteId = newAn.Id
# 		newAr.save
# 	end
# end


######################################################

# ar1 = AnalyteRange.find_by(AnalyteId: 314).dup
# ar1.assign_attributes(Name: "Mężczyzna", Gender: 0, AgeTo: 150, AgeToMonth: 0, AgeToInMonths: 1800, Multiplier: 2.17)

# ar1k = ar1.dup
# ar1k.assign_attributes(Name: "Kobieta", Gender: 1, AgeTo: 150, AgeToMonth: 0, AgeToInMonths: 1800, Multiplier: 2.17)

# ar2 = AnalyteRange.find_by(AnalyteId: 315).dup
# ar2.assign_attributes(Name: "Mężczyzna", Gender: 0, AgeTo: 150, AgeToMonth: 0, AgeToInMonths: 1800, Multiplier: 2.17)

# ar2k = ar2.dup
# ar2k.assign_attributes(Name: "Kobieta", Gender: 1, AgeTo: 150, AgeToMonth: 0, AgeToInMonths: 1800, Multiplier: 2.17)

# AnalyteRange.where(AnalyteId: [314,315]).destroy_all

# ar1.save
# ar1k.save
# ar2.save
# ar2k.save

# ar3 = AnalyteRange.find_by(AnalyteId: 316).dup
# ar3.assign_attributes(Name: "Mężczyzna", Gender: 0, AgeTo: 150, AgeToMonth: 0, AgeToInMonths: 1800, Multiplier: 1.00)

# ar3k = ar3.dup
# ar3k.assign_attributes(Name: "Kobieta", Gender: 1, AgeTo: 150, AgeToMonth: 0, AgeToInMonths: 1800, Multiplier: 1.00)
# AnalyteRange.where(AnalyteId: 316).destroy_all

# ar3.save
# ar3k.save