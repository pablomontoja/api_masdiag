class SoakingDegree < ApplicationRecord
	has_many :samples, class_name: "Sample", foreign_key: "Id"
end