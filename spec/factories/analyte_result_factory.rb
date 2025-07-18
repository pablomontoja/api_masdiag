# == Schema Information
#
# Table name: AnalyteResults
#
#  ResultId             :integer          not null, primary key
#  AnalyteId            :integer          not null, primary key
#  Value                :decimal(18, 2)   not null
#  Unit                 :text(4294967295)
#  Result_MeasurementId :integer
#  MeasuredValue        :decimal(18, 5)   not null
#
FactoryBot.define do
  factory :analyte_result, class: AnalyteResult do
    Value { 0.01 }
    Unit { "ng/ml" }
    MeasuredValue { 0.0100 }
  end
end
