# == Schema Information
#
# Table name: measurement_summaries
#
#  id             :bigint           not null, primary key
#  name           :string(255)
#  institution_id :integer          not null
#  from_date      :date
#  to_date        :date
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class MeasurementSummary < ApplicationRecord
  belongs_to :institution
  has_many :measurement_summary_items, dependent: :destroy
  has_many :samples, through: :measurement_summary_items, source: :sample
  has_many :measurements, through: :measurement_summary_items, source: :measurement

  validates :name, presence: true, uniqueness: { scope: :institution_id }
  validates :from_date, presence: true
  validates :to_date, presence: true
  # validate :unique_month_per_institution

  # {[project_id, test_variant]=>volume, ...}
  # {[2, nil]=>1237, [3, nil]=>558, [10, "c+vitaeq10-dbs"]=>27, [10, "c+vitamin-a-dbs"]=>25, [12, nil]=>61, [21, nil]=>316, [22, nil]=>2508, [23, nil]=>176, [29, nil]=>76}
  def grouped_items
    grouped_items = self.measurement_summary_items.group(:project_id, :test_variant, :test_id).count
    grouped_items.map do |test_variant_project, volume|
      test = Test.find(test_variant_project[2])
      test_variant = test_variant_project[1]
      project_name = Project.find(test_variant_project[0])&.Name
      OpenStruct.new(project_name: project_name, test_name: test&.name, test_variant: test_variant, volume: volume)
    end    
  end

  def self.search(search)
    if search.present?
      base_query = self.includes(measurements: :sample).includes(:institution).references(:Samples, :Measurements, :institutions)

      base_query.where("Samples.Code LIKE ?", "%#{search}%")
        .or(base_query.where("measurement_summaries.name LIKE ?", "%#{search}%"))
        .or(base_query.where("institutions.name LIKE ?", "%#{search}%"))
    else
      self.all
    end
  end

  # private

  # def unique_month_per_institution
  #   return unless from_date && institution_id

  #   # Get the year and month from from_date
  #   year_month = from_date.beginning_of_month

  #   # Check for existing records in the same month and institution
  #   existing_record = MeasurementSummary.where(
  #     institution_id: institution_id,
  #     from_date: year_month..year_month.end_of_month
  #   ).where.not(id: id) # Exclude current record for updates

  #   if existing_record.exists?
  #     errors.add(:from_date, "Only one measurement summary per month per institution is allowed")
  #   end
  # end
end
