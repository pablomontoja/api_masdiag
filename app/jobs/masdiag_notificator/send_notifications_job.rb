module MasdiagNotificator
  class SendNotificationsJob < ApplicationJob

    def perform() 
      byebug     
      contractor_ids = Contractor.where(are_notifications_enabled: true).pluck(:Id)
      files = OnlineFile.includes(measurement: { sample: { patient: :contractor}}).where(measurement: {sample: {Patients: {ContractorId: contractor_ids}}})\
                        .where(is_notification_send: false).pluck(:measurement_id, :"Patients.ContractorId")      
    	return nil if files.count == 0
    	
    	h = Hash.new  # hash gdzie kluczami są idki z OnlineFile a wartościami są idki z Contractor
     	files.collect{|x| h[x[0]] = x[1]} # generowanie tablicy hashy
    	contractors = h.values.uniq # kompresja klientów

      # byebug

    	contractors.each do |contractor|
    		contractor_files = h.select{|x,y| y==contractor}
    		file_ids = contractor_files.keys
        byebug      
    		ResultNotificationMailer.notify_by_mail(contractor, file_ids).deliver_later   
        # byebug     
    	end
    end
    
  end
end