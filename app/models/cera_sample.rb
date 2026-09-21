# == Schema Information
#
# Table name: CeraSamples
#
#  Id                    :integer          not null, primary key
#  SampleId              :integer          not null
#  BadQuality            :boolean          not null
#  IsResultSentToCera    :boolean          not null
#  ResultSentToCeraDate  :datetime
#  CeraType              :text(4294967295)
#  CheckupJson           :text(4294967295)
#  PatientId             :integer
#  CsvFileId             :integer
#  IsResultSendInCsvFile :boolean          not null
#  CeraTestedAt          :datetime
#  MasdiagProjectId      :integer          not null
#
class CeraSample < ApplicationRecord
  self.table_name = "CeraSamples"
  self.primary_key = "Id"

  belongs_to :sample, class_name: "Sample", foreign_key: "SampleId"

end
