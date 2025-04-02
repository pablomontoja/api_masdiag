class PlateMeasurement < ApplicationRecord
	self.table_name = "PlateMeasurements"
	self.primary_key = "MeasurementId"

	validates :PlatePosition, presence: true, uniqueness: { scope: :PlateId }, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 98,  only_integer: true }

	belongs_to :measurement, class_name: "Measurement", foreign_key: "MeasurementId"
	belongs_to :plate, class_name: "Plate", foreign_key: "PlateId", inverse_of: :plate_measurements
end