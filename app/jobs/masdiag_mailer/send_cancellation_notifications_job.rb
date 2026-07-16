module MasdiagMailer
	class SendCancellationNotificationsJob < ApplicationJob
	  require 'json'
	  # include Sidekiq::Worker

	  def perform(sample_ids)
	    begin
	      sample_ids.each do |sample_id|

	        @sample = Sample.find(sample_id)
	        next if @sample == nil
	        next if @sample&.patient&.contractor&.api_account

	        # pudełko pochodzące z LEKAMu
	        rsc_box = ReservedSampleCode.includes(package: :product).where(package: {products: {type: [1, 4]}}).where(IsRetailSale: true).find_by(Code: @sample.Code)
	        if rsc_box != nil && rsc_box&.InstitutionId == 32
	          patient_email = @sample.patient.email if !@sample.patient&.email&.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        # pudełko pochodzące z AQIPHARM
	        if rsc_box != nil && rsc_box&.InstitutionId == 34
	          patient_email = @sample.patient.email if !@sample.patient&.email&.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_dziopa(sample_id).deliver_later
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        # pudełko od zarejestrowanej próbki
	        if !@sample.patient.IsVirtual && rsc_box != nil && rsc_box.parent_id == nil
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        # pudełko zapasowe
	        if !@sample.patient.IsVirtual && rsc_box != nil && rsc_box.parent_id != nil
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?
	          # MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient(sample_id).deliver_later if patient_email != nil
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        # pudełko IsRetailSale:false od próbki zarejestrowanej poprzez partnerzy.masdiag.pl
	        rsc_box_without_retail_sale = ReservedSampleCode.includes(package: :product).where(package: {products: {type: [1, 4]}}).where(IsRetailSale: false).find_by(Code: @sample.Code)
	        if !@sample.patient.IsVirtual && rsc_box_without_retail_sale != nil && rsc_box_without_retail_sale.parent_id == nil && @sample.test_transaction.present?
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient(sample_id).deliver_later if patient_email != nil
	          next
	        end

	        #pudełko DIAGNOSTYKI PRECYZYJNEJ
	        if !@sample.patient.IsVirtual && !@sample.rsc&.shop_order.nil?
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient(sample_id).deliver_later if patient_email != nil
	          next
	        end


	        # anulowane kody paskowe
	        if /\A\d+\Z/.match?(@sample.Code) && (5000..15373).include?(Integer(@sample.Code))
	          if !@sample.patient.IsVirtual
	            contractor = Contractor.find(@sample.patient.ContractorId)
	            MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_contractor(sample_id, contractor.email).deliver_later if !contractor&.email.blank?
	            next
	          end
	        end

	        # anulowany LEKAM, pierwsze zamówienie
	        if /\A\d+\Z/.match?(@sample.Code) && (20000..22059).include?(Integer(@sample.Code))
	          if !@sample.patient.IsVirtual
	            contractor = Contractor.find(@sample.patient.ContractorId)
	            MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_contractor(sample_id, contractor.email).deliver_later if !contractor&.email.blank?
	            next
	          end
	        end

	        # do lekarzy, bibuła nie z pudełka
	        not_rsc_box = ReservedSampleCode.includes(package: :product).where.not(package: {products: {type: [1, 4]}}).find_by(Code: @sample.Code)
	        if !@sample.patient.IsVirtual && not_rsc_box != nil
	          contractor = Contractor.find(@sample.patient.ContractorId)
	          MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_contractor(sample_id, contractor.email).deliver_later if !contractor&.email.blank?
	        end

	        # do pacjenta, bibuła nie z pudełka
	        if !@sample.patient.IsVirtual && not_rsc_box != nil
	          patient_email = @sample.patient.email if !@sample.patient.email.blank?

	          # TODO institutions excluded from SendCancellationNotificationsMailer#send_mail_to_patient_standard_dbs_paper should be at configuration or database level (flag as column in DB)
	          if @sample.patient.contractor.institution_id != 87 # HolisticaMed Aleksandra Ściebur
	            MasdiagMailer::SendCancellationNotificationsMailer.send_mail_to_patient_standard_dbs_paper(sample_id).deliver_later if patient_email != nil && patient_email != "null"
	          end
	        end

	      end

	    rescue StandardError => err
	      MasdiagMailer::SendErrorNotificationsMailer.send_mail({SendCancellationNotificationsJob: "ERROR: #{err}", SampleCode: @sample.Code}).deliver_later
	    end
	  end


	end
end
