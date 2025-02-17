class MailNotificationService < ApplicationService
  require 'net/http'
  attr_reader :resource

  def initialize(action, resource)
    @action = action
    @resource = resource
  end

  def call
    begin
      Sentry.capture_message("Someone use MailNotificationService in api_masdiag. It is deprecated and should not be used. Resource: #{@resource}")
      
      attempts ||= 1
      uri_string = Rails.application.credentials.external_mailer[:url]
      uri = URI.parse("#{uri_string}/#{@action}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.instance_of? URI::HTTPS

      req = Net::HTTP::Post.new(uri, {'Content-Type': 'application/json'})
      req.basic_auth Rails.application.credentials.external_mailer[:name], Rails.application.credentials.external_mailer[:password]

      case @action
      when "send_notification_after_delayed_reg"
        req.body = {sample_id: @resource.Id}.to_json
      when "send_cancellation_notifications"
        req.body = {sample_ids: [@resource.Id]}.to_json
      when "after_new_order_save"
        req.body = {shop_order_id: @resource.id}.to_json
      when "shipping_after_new_order"
        req.body = {shop_order_id: @resource.id}.to_json
      when "after_sample_registration"
        req.body = {sample_id: @resource.Id}.to_json
      when "aqipharm_registration"
        req.body = {sample_id: @resource.Id}.to_json
      when "send_error_notifications"
        req.body = @resource.to_json
      end



      response = http.request(req)

      if response.code != "200"
        errors = [Time.current.to_s, "MASDIAG API --> #{self.class.name}", "action: #{@action}", "message - #{response.msg}", "response body - #{response.body}", caller_locations.join("<br>")]
        puts errors
        # IndMailer.after_error(errorsSentry.capture_exception(ex).flatten).deliver_later
        raise StandardError
      end
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => ex
      Sentry.capture_exception(ex)
      if (attempts += 1) < 10
        sleep attempts*10
        puts "<--------- retrying #{self.class.name} - attempt: #{attempts} --------->"
        retry
      end
      errors = [Time.current.to_s, "MASDIAG API --> #{self.class.name}", "action: #{@action}", "Exception - #{ex}", "@resource - #{@sample.to_json}", caller_locations.join("<br>")]
      puts errors
      # IndMailer.after_error(errors.flatten).deliver_later
    end
  end

end
