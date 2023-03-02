class Analyte < ApplicationRecord
	self.table_name = "Analytes"
	self.primary_key = "Id"

	belongs_to :project, class_name: "Project", foreign_key: "ProjectId"

  def readonly?
    true
  end

end