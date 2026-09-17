# == Schema Information
#
# Table name: GaSamples
#
#  Id                :integer          not null, primary key
#  SampleId          :integer          not null
#  PatientId         :integer          not null
#  BadQuality        :boolean          not null
#  IsResultSent      :boolean          not null
#  ResultSentDate    :datetime
#  Type              :text(4294967295)
#  MasdiagProjectId  :integer          not null
#  SampleCollectedAt :datetime
#  CheckupJson       :text(4294967295)
#
class GaSample < ApplicationRecord
  self.table_name = "GaSamples"
  self.primary_key = "Id"

  belongs_to :sample, class_name: "Sample", foreign_key: "SampleId"

end
