# LSI validation

As part of the validation of the LSI Masdiag software in accordance with IEC 62304, it is necessary to prepare a software configuration report with each software release.
A script has been created that prepares the data needed to prepare the report.

To run validation script please use the following command:
```bash
rails runner LSI_validation.rb
```



# Typical workflow for API samples

1. You must declare to us which sample codes you will use. At the moment, it is not possible to do this via the API. When we get the list of codes, we check that the declared sample codes are not already in our database. This is to ensure uniqueness. We recommend using at least eight-character alphanumeric codes (a good solution is not to use the letter O and the number 0).
2. The next step is to assign the test to the sample code - MasdiagAPI - POST /fv1/kits/assign_tests
You will get a list of the tests you will be dealing with in the next week. You will also get a list of sample codes to test the API in a sandbox environment.
The test assignment step can be done at the previous point if you know in advance that the kits produced will be for a specific test.
3. The sample/kit must then be registered via the API. MasdiagAPI - POST /fv1/sample
To some extent, the data provided in this step can be anonymised. We do not need to know the first and last name, but it would be good to know the patient's real gender and date of birth, as this is often needed to issue a correct analysis result.
4. The next step is to communicate that the sample has arrived at the laboratory, to communicate that the sample has been cancelled and to communicate the result.
MasdiagAPI - GET /fv1/result/get/:code  or we send JSON to configured webhook
I'm deliberately writing about this in one paragraph, because the information is transmitted in the same way via a single API endpoint, or sent to a configured Webhook, but there is always a similar JSON just containing different information. Please refer to the attached documentation for details.



# Checking not included in measurement summaries
```ruby
Measurement.includes(sample: { patient: { contractor: :institution }}).where(sample: { patient: { contractor: { institutions: { kind: ["Hospital", "ForeignInstitution"] }}}}).where(Status: 5, AuthorizedAt: Date.parse("2025-07-01")..Date.parse("2025-09-01")).where.not(
  Id: MeasurementSummaryItem.where(created_at: Date.parse("2025-06-01")..nil).select(:measurement_id)
).pluck("sample.Code")



Measurement.includes(sample: { patient: { contractor: :institution }}).where(sample: { patient: { contractor: { institutions: { kind: ["ForeignInstitution"] }}}}).where(Status: 4, MeasureDate: Date.parse("2025-07-01")..Date.parse("2025-09-01")).where.not(
  Id: MeasurementSummaryItem.where(created_at: Date.parse("2025-06-01")..nil).select(:measurement_id)
).pluck("sample.Code")
```



# Transfer EU barcodes to AU
```ruby
# in MASDIAG.COM database
accs = ["Age Well 360",                                         
 "Balgowlah Family Practice",                            
 "Botanica Medica Wellness Centre",                      
 "Cassandra Lawless",                                    
 "Chi Longevity"]
ids = HcpAccount.where(business_name: accs).pluck(:id)
Kit.where(account_id: ids).pluck(:code).join(" ")

# transfer all codes to AU in LabSample DB
codes = %w[EUAC829920]
ReservedSampleCode.where(Code: codes).update_all(InstitutionId: 85)

Sample.includes(patient: :contractor).where(Code: codes).each do |sample|
	puts "------------------------------------------------------------------"
	puts "#{sample.patient.FirstName} #{sample.patient.LastName}"
	if sample.patient.FirstName == "FAKE"
		puts "FAKE"
		sample.update(PatientId: 340608)
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


Things you may want to cover:

* Ruby version
* System dependencies
* Configuration
* Database creation
* Database initialization
* How to run the test suite
* Services (job queues, cache servers, search engines, etc.)
* Deployment instructions
* ...



