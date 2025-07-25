module DiagnostykaPrecyzyjna
  class AppointmentCreationJob < ApplicationJob
    require 'net/http'
    queue_as :default

    retry_on StandardError, wait: 30.minutes, attempts: 10 do |job, error|
      Sentry.capture_exception(error)
    end

    def perform(appointment)
      uri_string = Rails.application.credentials.patient_portal_api[:url]

      uri = URI.parse(uri_string)
      req = Net::HTTP::Post.new(uri, {'Content-Type': 'application/json'})

      req.basic_auth Rails.application.credentials.patient_portal_api[:username],
                     Rails.application.credentials.patient_portal_api[:password]

      req.body = { appointment: appointment }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end  
    end
    
  end
end