# == Schema Information
#
# Table name: Measurements
#
#  Id                :integer          not null, primary key
#  SampleId          :integer          not null
#  ProjectId         :integer          not null
#  ResultId          :integer
#  IsRepeat          :boolean          default(FALSE), not null
#  Status            :integer          not null
#  MeasureDate       :datetime
#  IsValid           :boolean          default(FALSE), not null
#  LabCode           :text(4294967295)
#  CreatedById       :integer
#  CreatedAt         :datetime
#  ModifiedById      :integer
#  ModifiedAt        :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  AuthorizedById    :integer
#  AuthorizedAt      :datetime
#  CuttedAt          :datetime
#  selected_analytes :text(65535)
#  InstrumentId      :integer
#  MaterialType      :integer          default(0), not null
#
class Measurement < ApplicationRecord
	self.table_name = "Measurements"
	self.primary_key = "Id"
	
	before_save :set_time_stamps

	belongs_to :sample, class_name: 'Sample', foreign_key: 'SampleId', inverse_of: :measurements
	belongs_to :project, class_name: "Project", foreign_key: "ProjectId"
	has_one :online_file, dependent: :destroy
	has_one :plate_measurement, class_name: "PlateMeasurement", foreign_key: "MeasurementId", dependent: :destroy
	# has_one :plate, through: :plate_measurement
	has_one :result, class_name: "Result", foreign_key: "MeasurementId", dependent: :destroy
  
  def set_time_stamps
    self.CreatedAt = DateTime.now if self.new_record?
    self.IsValid = true if self.new_record?
    self.ModifiedAt = DateTime.now
  end

end
