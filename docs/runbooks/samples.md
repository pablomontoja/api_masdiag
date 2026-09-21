# Runbook: operacje na próbkach

> Snippety uruchamiane **ręcznie z konsoli Rails**, jednorazowo, na konkretnych kodach próbek.
> Część jest **nieodwracalna** (`destroy_all`, `update_all`, `update_columns` pomijające walidacje
> i callbacki). Przed uruchomieniem podmień kody/ID na własne i sprawdź, na której bazie działasz.

## LALEN FAL cheats
```ruby
ReservedSampleCode.find_by(Code: "GB81I5PM").assign_tests_in_lalen_api

Sample.find_by(Code: "GB81I5PM").register_in_lalen_api


codes = %w[]
ReservedSampleCode.where(Code: codes).each do |rsc|
	rsc.assign_tests_in_lalen_api
end

Sample.where(Code: codes).each do |s|
	s.register_in_lalen_api
end
```

## Naprawa płytki (undamage plate)
```ruby
plate_id = 21394

plate = Plate.find(plate_id)

plate.measurements.each do |m|
	meas = m.sample.measurements.includes(:sample).where(Samples: { IsControlSample: false }).find_by(ProjectId: plate.ProjectId, Status: 1)
	meas.destroy unless meas.nil?
	m.update(Status: 2)
end

plate.update(IsValid: false)

```

## Próbka QNS po akceptacji w laboratorium
```ruby
codes = %w[AUREWFTG AUU7TIHQ AUCD5TE7 AUB45H9C AUIW2BC9 AUJNFBL4 AUIXWNTX]
reason = %q(
Hi Lalen

We have received 5 DBS cards from you for measuring glutathione levels. Unfortunately, these cards have expired. We have tested these samples, but the glutathione levels were found to be low. We must cancel these samples and mark them as QNS. Please send new cards to the customer. Below is a list of these samples with their production and expiry dates.

AUUYSNGE - EXP 11-01-2025 - MANUFACTURED 10-2024
AUREWFTG - EXP 20-12-2025 - MANUFACTURED 12-2024
AUU7TIHQ - EXP 20-12-2025 - MANUFACTURED 12-2024
AUCD5TE7 - EXP 20-12-2025 - MANUFACTURED 12-2024
AUB45H9C - EXP 20-12-2025 - MANUFACTURED 12-2024

We have also received three DBS cards from you for vitamins A, E and Q10. These have also expired. We are unable to issue results for them.
The codes for these samples are listed below.

AUIW2BC9, AUJNFBL4, AUIXWNTX

Best regards,

Renata

Renata Halak
Diagnostic laboratory manager
)

user = User.find_by(email: "pawelswider@gmail.com")

Measurement.includes(:sample).where(Samples: { Code: codes }).destroy_all
Sample.where(Code: codes).each do |sample|
	sample.update(Comment: reason, SampleStatus: 4, CancelledById: user.Id, CancellationDate: DateTime.now)
	#Notification::LalenSampleResultSender.perform_later(sample)
end

```

## Transfer kodów EU ↔ AU
```ruby
# in MASDIAG.COM database
accs = ["Age Well 360",                                         
 "Balgowlah Family Practice",                            
 "Botanica Medica Wellness Centre",                      
 "Cassandra Lawless",                                    
 "Chi Longevity"]
ids = HcpAccount.where(business_name: accs).pluck(:id)
Kit.where(account_id: ids).pluck(:code).join(" ")

# place all printed in cli codes in sample.txt file and transfer all codes to AU in LabSample DB
codes = []

File.open('sample.txt', 'r') do |file|
  file.each_line do |line|
    codes.concat(line.strip.split)
  end
end

# codes = %w[EUAC829920]
ReservedSampleCode.where(Code: codes).update_all(InstitutionId: 85)

Sample.includes(patient: :contractor).where(Code: codes).each do |sample|
	puts "------------------------------------------------------------------"
	puts "#{sample.patient.FirstName} #{sample.patient.LastName}"
	if sample.patient.FirstName == "FAKE"
		puts "FAKE"
		sample.update_columns(PatientId: 340608)
		next
	else
		next if sample.patient.IsVirtual == true
		sample.patient.update_columns(ContractorId: 754)
		puts "REAL PATIENT"
	end
	nil
end



#---------------------------------------------------------
# transfer all codes to EU
#---------------------------------------------------------
# in MASDIAG.COM database
accs = ["Arctic Health AB",
"Beps Biopharm",
"ICTAN-CSIC",
"Nutilab",
"Wellness Innovations BV"]
ids = HcpAccount.where(business_name: accs).pluck(:id)
codes = %w[EUAC829920]
Kit.where(account_id: ids).pluck(:code).join(" ")
#---------------------------------------------------------
# in LabSampleDB
ReservedSampleCode.where(Code: codes).update_all(InstitutionId: 89)

Sample.includes(patient: :contractor).where(Code: codes).each do |sample|
	puts "------------------------------------------------------------------"
	puts "#{sample.patient.FirstName} #{sample.patient.LastName}"
	if sample.patient.FirstName == "FAKE"
		puts "FAKE"
		sample.update(PatientId: 384093)
		next
	else
		next if sample.patient.IsVirtual == true
		sample.patient.update_columns(ContractorId: 786)
		puts "REAL PATIENT"
	end
	nil
end
#---------------------------------------------------------

```
