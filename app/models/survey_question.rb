class SurveyQuestion < ApplicationRecord
	# extend Mobility
  belongs_to :project, class_name: "Project", foreign_key: "Project_id"
  has_and_belongs_to_many :options
  # translates :question_text, type: :text, locale_accessors: [:pl, :en]

  def readonly?
    true
  end

end
