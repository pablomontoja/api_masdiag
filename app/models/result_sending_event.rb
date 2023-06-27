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