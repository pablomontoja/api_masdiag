# == Schema Information
#
# Table name: Plates
#
#  Id                 :integer          not null, primary key
#  ProjectId          :integer          not null
#  RegistrationDate   :datetime         not null
#  Code               :text(4294967295) not null
#  IsValid            :boolean          not null
#  CreatedById        :integer          not null
#  CreatedAt          :datetime         not null
#  ModifiedById       :integer
#  ModifiedAt         :datetime
#  ResultWasAdded     :boolean          not null
#  ResultWasAddedDate :datetime
#  IsPartOfMultiplex  :boolean          not null
#  MultiplexId        :integer
#  Suffix             :integer          not null
#
class Plate < ApplicationRecord
	self.table_name = "Plates"
	self.primary_key = "Id"

	# belongs_to :measurement, class_name: "Measurement", foreign_key: "MeasurementId"
	has_many :plate_measurements, class_name: "PlateMeasurement", foreign_key: "PlateId", dependent: :destroy, inverse_of: :plate
end
