# == Schema Information
#
# Table name: survey_questions
#
#  id                       :integer          not null, primary key
#  question_text            :text(65535)
#  Project_id               :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  has_other_field          :boolean
#  is_second_level_question :boolean          default(FALSE), not null
#  is_required              :boolean          default(FALSE)
#  is_multichoice           :boolean          default(FALSE), not null
#  position                 :integer          default(0), not null
#
class SurveyQuestion < ApplicationRecord
	# extend Mobility
  belongs_to :project, class_name: "Project", foreign_key: "Project_id"
  has_and_belongs_to_many :options
  # translates :question_text, type: :text, locale_accessors: [:pl, :en]

  def readonly?
    true
  end

end
