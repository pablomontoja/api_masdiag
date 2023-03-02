class Option < ApplicationRecord
  has_and_belongs_to_many :survey_questions

  def readonly?
    true
  end

end
