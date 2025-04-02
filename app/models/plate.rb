class Plate < ApplicationRecord
	self.table_name = "Plates"
	self.primary_key = "Id"

	# belongs_to :measurement, class_name: "Measurement", foreign_key: "MeasurementId"
	has_many :plate_measurements, class_name: "PlateMeasurement", foreign_key: "PlateId", dependent: :destroy, inverse_of: :plate
end