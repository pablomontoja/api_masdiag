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

	validates :key, presence: true
	validates :subject_id, uniqueness: { scope: [:subject_type, :key] }
	validates_inclusion_of :key, in: :available_keys

private

	def available_keys
		%w( 
				included-in-monthly-hospital-report
				included-in-daily-hospital-zip-archive
				lalen-eu-incoming-samples-email
				included-in-monthly-ptc-report
				cerascreen-dao-declaration-email
				kit-lock
				lalen-eu-result-exit-in-xlsx
			)
	end

end
