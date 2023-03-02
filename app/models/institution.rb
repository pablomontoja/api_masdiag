class Institution < ApplicationRecord	
	has_many :contractors, class_name: "Contractor", foreign_key: "institution_id"
	has_many :patients, through: :contractors

	# belongs_to :discount, optional: true
	# belongs_to :agent, foreign_key: "created_by_agent_id", optional: true
	# has_and_belongs_to_many :projects, join_table: "institutions_projects"

	# before_validation :remove_whitespaces_and_dashes_in_nip

	# validates :name, presence: true, uniqueness: true
	# validates :nip, presence: true, uniqueness: true, length: { is: 10 }, if: Proc.new { |i| i.region_of_activity == 0 }
	# validates :email, presence: true, if: Proc.new { |i| i.approve_contractor_after_registration }

  def fullname
  	if self.region_of_activity == 0
  		"#{self.name} - NIP #{self.nip}"
  	else
  		"#{self.name} - Instytucja Zagraniczna #{self.nip}"
  	end    
  end

  def readonly?
    Rails.env.test? ? false : true
  end 

private

	# def remove_whitespaces_and_dashes_in_nip
	# 	nip.strip!
	# 	nip.gsub!(/[^0-9]/, "")
	# end

end
