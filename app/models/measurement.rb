class Measurement < ApplicationRecord
	self.table_name = "Measurements"
	self.primary_key = "Id"
	
	before_save :set_time_stamps

	belongs_to :sample, class_name: 'Sample', foreign_key: 'SampleId', inverse_of: :measurements
	belongs_to :project, class_name: "Project", foreign_key: "ProjectId"
	has_one :online_file, dependent: :destroy
	has_one :result, class_name: "Result", foreign_key: "MeasurementId"
  
  def set_time_stamps
    self.CreatedAt = DateTime.now if self.new_record?
    self.IsValid = true if self.new_record?
    self.ModifiedAt = DateTime.now
  end

end
