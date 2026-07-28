# == Schema Information
#
# Table name: notes
#
#  id           :bigint           not null, primary key
#  description  :text(65535)
#  key          :string(255)
#  subject_type :string(255)      not null
#  subject_id   :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Note < ApplicationRecord
	belongs_to :subject, polymorphic: true

	KEYS_BY_SUBJECT = {
		"Sample" => %w[
			lalen-eu-incoming-samples-email
			stability-period-exceeded
			tandem-ms-sample
			alloisoleucine-sample
			extended-metabolic-screening
			sample-registration-confirmation-email
			sample-accepted-email
			registration-reminder-email
			registration-reminder-final-email
			sample-rejected-email
			result-available-email
			chromatogram-request-email
			lab-user-note
		],
		"ReservedSampleCode" => %w[
			cerascreen-dao-declaration-email
			kit-lock
			cancelled-handler
			free-or-demo
			lab-user-note
		],
		"Measurement" => %w[
			included-in-monthly-hospital-report
			included-in-daily-hospital-zip-archive
			included-in-monthly-ptc-report
			included-in-monthly-invoice-for-hospitals
			omegaquant-result-exit-in-csv
			lab-user-note
		]
	}.freeze

	def self.keys_for(subject_type)
		KEYS_BY_SUBJECT.fetch(subject_type.to_s, [])
	end

	validates :key, presence: true
	validates :subject_id, uniqueness: { scope: [:subject_type, :key] }
	validates_inclusion_of :key, in: :available_keys

private

	def available_keys
		KEYS_BY_SUBJECT.values.flatten.uniq
	end

end

# REMOVED KEYS
# 	lalen-eu-result-exit-in-xlsx
