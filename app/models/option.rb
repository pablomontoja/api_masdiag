# == Schema Information
#
# Table name: options
#
#  id                         :integer          not null, primary key
#  option_text                :text(65535)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  has_second_level_questions :boolean          default(FALSE), not null
#  is_other_option            :boolean          default(FALSE), not null
#
class Option < ApplicationRecord
  has_and_belongs_to_many :survey_questions

  def readonly?
    true
  end

end
