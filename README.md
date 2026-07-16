# API MASDIAG

## NEW MAILER MIGRATION

```bash
# Create database 'solid_queue_db'
bin/rails db:create
```


## TOXO migration
1. rails db:migrate
2. after "Mysql2::Error: Table 'LabSample.mobility_string_translations' doesn't exist" error comment `extend Mobility` and `translates :NameInReport, type: :string, default: -> { read_attribute(:NameInReport) }`
3. use `rails c` and `require Rails.root.join('db/migrate/20260311113835_toxicology_quant_project')` and `ToxicologyQuantProject.new.change`
4. add `20260311113835` to schema_migrations table
5. uncomment `extend Mobility` and `translates :NameInReport, type: :string, default: -> { read_attribute(:NameInReport) }`
6. rails db:migrate

---

# TODO in README.md
- authentication controller for mission_control gem, currently config.mission_control.jobs.http_basic_auth_enabled is false
- new layout for /rails/mailers/cancellation_notification_mailer/send_mail_to_contractor
- new layout for /rails/mailers/cancellation_notification_mailer/send_mail_to_patient
- new layout for /rails/mailers/cancellation_notification_mailer/standard_cancellation_notification
- new layout for /rails/mailers/result_notification_mailer/contractor_result_notification_mailer
- new layout for /rails/mailers/result_notification_mailer/patient_result_notification_mailer_lekam



# MasdiagMailer/MasdiagRecurring Notes

List of tasks to do during deployment on production
1. perhaps Dockerfile7.1 should be used for deploy in production 
2. rails db:prepare    ---- it is needed for solid_queue migration if first task is not proceeded
3. if "Specified key was too long max key length is 767 bytes" problem occurs go to Masdiag Obsidian and find solution
4. rails db:migrate:queue  ---- applying solid_queue DB changes
5. enabling YJIT in production and verification, see "Enabling ruby YJIT" below

Comments:
1. patient_portal doesn't work properly, see what happen when appiontment request is sent (DiagnostykaPrecyzyjna::AppointmentBuilderService)




# LSI validation

As part of the validation of the LSI Masdiag software in accordance with IEC 62304, it is necessary to prepare a software configuration report with each software release.
A script has been created that prepares the data needed to prepare the report.

To run validation script please use the following command:
```bash
rails runner LSI_validation.rb
```

### PROMPTS

`git log --pretty=format:"%h - %an, %cd : %s" b2079cbfecd32fc1b1702f040bc399d43e5eca46..6ef70b987fd7c4847ba6166988edd3508d6994e3
List all commits from dd68a0a9afb614e9bf484af6d848121379752c1d to d18c53fadbc8f40e1209f1cf72e9524bed3944d1.
Check all above git commits and gather info about changes across all commits between the specified range.
Finally create a table with a git hash (including the commit date in the same column beow the hash), a description of the changes, the category of changes (minor correction, security correction, backend change, frontend change, hotfixes, and so on), and the impact of the changes on patient safety (in the context of EN 62304)? Please use markdown format and translate content to Polish language. Order by by commit date, ascending.`

---

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

---

# LALEN FAL cheats
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


---

# Test DB preparation

```bash
rails db:schema:dump
rails tmp:clear
RAILS_ENV=test rails db:drop db:create db:schema:load
```

---

# Database schema reload during migration

```ruby
Test.reset_column_information
```

---

# Enabling ruby YJIT
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustc --version

rvm reinstall 3.3.7 --reconfigure --enable-yjit
ruby --yjit -e "p RubyVM::YJIT.enabled?" 
```




# Checking not included in measurement summaries
```ruby
Measurement.includes(sample: { patient: { contractor: :institution }}).where(sample: { patient: { contractor: { institutions: { kind: ["Hospital", "ForeignInstitution"] }}}}).where(Status: 5, AuthorizedAt: Date.parse("2025-07-01")..Date.parse("2025-09-01")).where.not(
  Id: MeasurementSummaryItem.where(created_at: Date.parse("2025-06-01")..nil).select(:measurement_id)
).pluck("sample.Code")



Measurement.includes(sample: { patient: { contractor: :institution }}).where(sample: { patient: { contractor: { institutions: { kind: ["ForeignInstitution"] }}}}).where(Status: 4, MeasureDate: Date.parse("2025-07-01")..Date.parse("2025-09-01")).where.not(
  Id: MeasurementSummaryItem.where(created_at: Date.parse("2025-06-01")..nil).select(:measurement_id)
).pluck("sample.Code")
```

# Run migrations from rails console
```ruby
require Rails.root.join('db/migrate/20260311113835_toxicology_quant_project')
ToxicologyQuantProject.new.change
```


# Undamage plate
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


# Export results by Institution and Project
```ruby
require "csv"
INST_ID = 128 # ORKLA
PROJECTID = 34

def extract_result_row(res)
	res.analyte_results.sort_by{|ar| ar.AnalyteId}.map { |ar| ar.Value  }
end

def sex(gender)
	return "M" if gender == 0
	return "K" if gender == 1
end

codes = ReservedSampleCode.where(InstitutionId: INST_ID).pluck(:Code)

r_ids = Result.includes(:measurement).includes(measurement: :sample).where(measurement: {Samples: {IsControlSample: false, Code: codes}}).where(Measurements: { ProjectId: PROJECTID, Status: [4, 5] }).order(MeasurementId: :desc).limit(10000).pluck(:MeasurementId)


CSV.open("tmp/aa-result-export-2.csv", "wb") do |csv|
	header = []
	header << "Kod"
	header << "Imię"
	header << "Nazwisko"
	header << "PESEL"
	header << "Płeć"
	header << "Data wydania"
	header << "Data urodzenia"
	header << "Data pobrania"
	header << "Wyjście z magazynu"

	header = header + Result.includes(:analyte_results).where(MeasurementId: r_ids).first.analyte_results.sort_by{|ar| ar.AnalyteId}.map { |ar| ar.analyte.Name  }

	pp header

	csv << header

	Result.includes(:analyte_results).includes(measurement: {sample: :patient}).where(MeasurementId: r_ids).find_in_batches(batch_size: 1000) do |group|	  
	  group.each do |res|
	  	pat = res.measurement.sample.patient 
	  	csv << [res.measurement.sample.Code, pat.FirstName, pat.LastName, pat.Pesel, sex(pat.Gender), res.measurement.AuthorizedAt&.strftime("%F"), pat.BirthDate&.strftime("%F"), res.measurement.sample.sample_collection_date&.strftime("%F"), res.measurement.sample.rsc&.package&.stock_room_item&.date_out&.strftime("%F")] + extract_result_row(res)
	  end
	end

end



```

# QNS sample after acceptance in Lab
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


# PROBLEMS

---

## Specified key was too long; max key length is 767 bytes

Open my.ini and add this lines(if they already exist just edit everything after =) right after [mysqld]:
```
innodb_file_format = Barracuda
innodb_file_per_table = on
innodb_default_row_format = dynamic
innodb_large_prefix = 1
innodb_file_format_max = Barracuda
```

OR

Autenticate to mysql:
```
mysql -h localhost -u root
```
or use phpmyadmin.

Once you're authenticated run this queries(one at a time):
```
SET GLOBAL innodb_file_format = Barracuda;
SET GLOBAL innodb_file_per_table = on;
SET GLOBAL innodb_default_row_format = dynamic;
SET GLOBAL innodb_large_prefix = 1;
SET GLOBAL innodb_file_format_max = Barracuda;
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



