# == Schema Information
#
# Table name: soaking_degrees
#
#  id   :integer          not null, primary key
#  name :text(4294967295)
#  sn   :integer          not null
#
class SoakingDegree < ApplicationRecord
	has_many :samples, class_name: "Sample", foreign_key: "Id"
end
