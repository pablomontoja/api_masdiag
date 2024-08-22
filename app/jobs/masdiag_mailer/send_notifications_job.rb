module MasdiagMailer
  class SendNotificationsJob < ApplicationJob

    def perform()
      contractor_ids = Contractor.where(are_notifications_enabled: true).pluck(:Id)
      files = OnlineFile.includes(measurement: { sample: { patient: :contractor}}).where(measurement: {sample: {Patients: {ContractorId: contractor_ids}}})\
                        .where(is_notification_send: false).pluck(:measurement_id, :"Patients.ContractorId")      
    	return nil if files.count == 0
    	
    	h = Hash.new  # hash gdzie kluczami są idki z OnlineFile a wartościami są idki z Contractor
     	files.collect{|x| h[x[0]] = x[1]} # generowanie tablicy hashy
    	contractors = h.values.uniq # kompresja klientów

    	contractors.each do |contractor|
    		contractor_files = h.select{|x,y| y==contractor}
    		file_ids = contractor_files.keys
    		MasdiagMailer::ResultNotificationMailer.send_mail(contractor, file_ids).deliver_later
    	end
    end
    
  end
end