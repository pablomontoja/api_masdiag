# == Schema Information
#
# Table name: result_sending_events
#
#  id                         :integer          not null, primary key
#  measurement_id             :integer
#  sample_id                  :integer          not null
#  sent_date                  :datetime
#  sent_through               :integer
#  recipient                  :text(4294967295)
#  address                    :text(4294967295)
#  result_text_representation :text(65535)
#
class ResultSendingEvent < ApplicationRecord	
	belongs_to :sample
	belongs_to :measurement, optional: true
	belongs_to :fileable, inverse_of: :result_sending_event, dependent: :destroy, class_name: "Fileable", foreign_key: "id"
  has_many :db_files, through: :fileable

	validates_presence_of :fileable, message: "fileable is needed!!!"
end

  #     sent_through
  #       Undefined = 0,
  #       EmailNotification,
  #       EmailPdf,
  #       CerascreenAPI,
  #       EmailCsv
