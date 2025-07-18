# == Schema Information
#
# Table name: db_files
#
#  id           :integer          not null, primary key
#  file_type    :text(4294967295)
#  file_length  :integer          not null
#  file_content :binary(16777215)
#  fileable_id  :integer          not null
#
class DbFile < ApplicationRecord	
	belongs_to :fileable#, optional: true
end
