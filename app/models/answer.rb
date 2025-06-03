# == Schema Information
#
# Table name: answers
#
#  id                 :integer          not null, primary key
#  option_id          :integer
#  survey_question_id :integer
#  Sample_id          :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  other_field_text   :text(65535)
#
class Answer < ApplicationRecord
  belongs_to :option
  belongs_to :survey_question
  belongs_to :sample, class_name: "Sample", foreign_key: "Sample_id", inverse_of: :answers
end
