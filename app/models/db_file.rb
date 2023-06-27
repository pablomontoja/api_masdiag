class DbFile < ApplicationRecord	
	belongs_to :fileable#, optional: true
end