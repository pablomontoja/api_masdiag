# == Schema Information
#
# Table name: measurement_summary_items
#
#  id                     :bigint           not null, primary key
#  measurement_summary_id :bigint           not null
#  measurement_id         :integer          not null
#  sample_id              :integer          not null
#  project_id             :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  test_variant           :string(255)
#  test_id                :bigint
#
class MeasurementSummaryItem < ApplicationRecord
  belongs_to :measurement_summary
  belongs_to :measurement, class_name: 'Measurement', foreign_key: "measurement_id", primary_key: "Id"
  belongs_to :sample, class_name: "Sample", foreign_key: "sample_id", primary_key: "Id"
  belongs_to :project
  belongs_to :test

  validates :project_id, uniqueness: { scope: :sample_id }
  validates :measurement_id, uniqueness: true
end
