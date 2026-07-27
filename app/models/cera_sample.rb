class CeraSample < ApplicationRecord
  self.table_name = "CeraSamples"
  self.primary_key = "Id"

  belongs_to :sample, class_name: "Sample", foreign_key: "SampleId"

end
