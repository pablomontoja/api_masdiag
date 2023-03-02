class ReservedTest < ApplicationRecord
	belongs_to :project, class_name: "Project", foreign_key: "project_id"
	belongs_to :reserved_sample_code, class_name: "ReservedSampleCode", foreign_key: "reserved_sample_code_id"
	validates :project_id, uniqueness: { scope: :reserved_sample_code_id }
end