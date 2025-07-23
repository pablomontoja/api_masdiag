class GaSample < ApplicationRecord
  self.table_name = "GaSamples"
  self.primary_key = "Id"

  belongs_to :sample, class_name: "Sample", foreign_key: "SampleId"

end
