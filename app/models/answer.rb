class Answer < ApplicationRecord
  belongs_to :option
  belongs_to :survey_question
  belongs_to :sample, class_name: "Sample", foreign_key: "Sample_id", inverse_of: :answers
end
