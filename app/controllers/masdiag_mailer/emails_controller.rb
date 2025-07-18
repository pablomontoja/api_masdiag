module MasdiagMailer
  class EmailsController < ApplicationController
    include MasdiagCheck

    # TODO all mailer endpoints in LabSample must be updated
    # GET /masdiag_mailer/send_all_mails(.:format)  ---->  masdiag_mailer/emails#send_all
    #                                                       
    # wykorzystywany przez LabSample do uruchomienia wysyłki wszystkich maili do zlecających i pacjentów
    def send_all
      if (Time.now - Rails.configuration.last_use_of_send_all_mail) < 60.seconds
        render json: { "error": "too many requests, the use of this endpoint is limited to 1 request per 60 seconds" }, status: 429
        return
      end

      MasdiagMailer::ContractorResultsNotifierJob.perform_later
      MasdiagMailer::PatientResultsNotifierJob.perform_later
      Rails.configuration.last_use_of_send_all_mail = Time.now

      render plain: "OK", status: 200
    end

    # POST   /masdiag_mailer/send_cancellation_notifications(.:format)  ---->  masdiag_mailer/emails#send_cancellation_notifications
    #
    # wykorzystywany przez LabSample w zakładce "Protokół przyjęcia próbek" do rozesłania maili dla anulowanych próbek
    def send_cancellation_notifications
      begin
        MasdiagMailer::SendCancellationNotificationsJob.perform_later(params["sample_ids"])
        render plain: "OK", status: 200
      rescue Exception => ex
        render json: { "error": ex.message }, status: 500
      end
    end

    # POST /mailer/send_acceptance_notifications
    # wykorzystywany przez LabSample w zakładce "Protokół przyjęcia próbek" do rozesłania maili dla przyjętych próbek
    def send_acceptance_notifications
      begin
        MasdiagMailer::SendAcceptanceNotificationsJob.perform_later(params["sample_ids"])
        render plain: "OK", status: 200
      rescue Exception => ex
        render json: { "error": ex.message }, status: 500
      end
    end

    # POST /mailer/send_error_notifications
    # raportowanie błędów - LabSample, indclients2
    def send_error_notifications
      begin
        MasdiagMailer::SendErrorNotificationsMailer.send_mail(params.to_unsafe_hash).deliver_later
        render plain: "OK", status: 200
      rescue Exception => ex
        render json: { "error": ex.message }, status: 500
      end
    end

    # POST   /masdiag_mailer/send_notification_after_delayed_reg(.:format)  ---->   masdiag_mailer/emails#send_notification_after_delayed_reg
    #
    def send_notification_after_delayed_reg
      begin
        MasdiagMailer::SendNotificationAfterDelayedRegJob.perform_later(params[:sample_id])
        render plain: "OK", status: 200
      rescue StandardError => ex
        render json: { "error": ex.message }, status: 500
      end
    end

    # POST /mailer/after_sample_registration
    # używany przez indclients2 do wysyłania powiadomień po rejestracji próbki
    def after_sample_registration
      begin
        if Measurement.where(SampleId: params[:sample_id], ProjectId: 25).any?
          MasdiagMailer::ThreeMethylDopaMailer.after_sample_registration(params[:sample_id]).deliver_later     
        else
          MasdiagMailer::IndMailer.after_sample_registration(params[:sample_id]).deliver_later
        end
        render plain: "OK", status: 200
      rescue StandardError => ex
        render json: { "error": ex.message }, status: 500
      end
    end

    # # POST /mailer/aqipharm_registration
    # #
    # def aqipharm_registration
    #   begin
    #     IndMailer.aqipharm_registration(params[:sample_id]).deliver_later
    #     render plain: "OK", status: 200
    #   rescue StandardError => ex
    #     render json: { "error": ex.message }, status: 500
    #   end
    # end

    # POST /mailer/shipping_after_new_order
    #
    def shipping_after_new_order
      begin
        MasdiagMailer::IndMailer.shipping_after_new_order(params[:shop_order_id]).deliver_later
        render plain: "OK", status: 200
      rescue StandardError => ex
        render json: { "error": ex.message }, status: 500
      end
    end

    # POST /mailer/after_new_order_save
    #
    def after_new_order_save
      begin
        MasdiagMailer::IndMailer.after_new_order_save(params[:shop_order_id]).deliver_later
        render plain: "OK", status: 200
      rescue StandardError => ex
        render json: { "error": ex.message }, status: 500
      end
    end

    # POST /mailer/masdiag_website_contact_form
    #
    # TODO masdiag_website_contact_form endpoint must be reconfigured at masdiag.pl site
    def masdiag_website_contact_form
      begin
        msg = { name: params[:name], email: params[:email], message: params[:message] }
        MasdiagMailer::MasdiagPlContactFormMailer.send_mail(msg).deliver_later
        render plain: "OK", status: 200
      rescue StandardError => ex
        render json: { "error": ex.message }, status: 500
      end
    end

  end
end