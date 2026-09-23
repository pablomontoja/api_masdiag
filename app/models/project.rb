# == Schema Information
#
# Table name: Projects
#
#  Id                       :integer          not null, primary key
#  Name                     :text(4294967295) not null
#  Description              :text(4294967295)
#  WithCutter               :boolean          not null
#  PlateDimensionX          :integer          not null
#  PlateDimensionY          :integer          not null
#  Prefix                   :text(4294967295)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  is_blocked_online        :boolean          default(FALSE), not null
#  survey_description       :text(65535)
#  PdfNameOfAnalysis        :text(4294967295)
#  PdfDescription           :text(4294967295)
#  product_name_in_invoice  :text(65535)
#  pkwiu_in_invoice         :string(255)
#  brutto_price             :decimal(6, 2)
#  FinalProtocoleHeader     :text(4294967295)
#  responsible_person_email :string(255)
#  has_selectable_analytes  :boolean
#  InjectionVolume          :decimal(4, 1)    not null
#  eng_name                 :string(255)
#  is_active                :boolean          default(TRUE), not null
#
class Project < ApplicationRecord
	extend Mobility
	self.table_name = "Projects"
	self.primary_key = "Id"

	translates :Name, type: :string, default: -> { read_attribute(:Name) }

	scope :enabled_online, -> { where(is_blocked_online: 'false') }

	has_many :measurements, class_name: "Measurement", foreign_key: "ProjectId"
	has_many :analytes, class_name: "Analyte", foreign_key: "ProjectId", dependent: :destroy
	has_many :reserved_tests
	has_many :reserved_sample_codes, through: :reserved_tests

	# Native `Name` column holds Polish text, but the app's ambient/default I18n
	# locale is :en (see config/application.rb) — so ambient locale can't be used
	# to decide where a write goes (a bare `project.Name = x` under the ambient
	# default must still land in the native column). Only an explicit `locale:`
	# keyword signals real translation intent; :pl explicitly always means native
	# column too, since it's never anything but the native language.
	def Name=(value, locale: nil, **options)
		explicit_locale = locale&.to_sym
		if explicit_locale.nil? || explicit_locale == :pl
			write_attribute(:Name, value)
		else
			super(value, locale: locale, **options)
		end
	end

  # def readonly?
  #   Rails.env.test? ? false : true
  # end

end
