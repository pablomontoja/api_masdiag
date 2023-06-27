class Fileable < ApplicationRecord	
	has_many :db_files, dependent: :destroy
	has_one :result_sending_event, class_name: "ResultSendingEvent", foreign_key: "id", inverse_of: :fileable, dependent: :destroy
	#validates_length_of :db_files, minimum: 1

	validates_presence_of :result_sending_event, message: "result_sending_event is needed!!!"
end