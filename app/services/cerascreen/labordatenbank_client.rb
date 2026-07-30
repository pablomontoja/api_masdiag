module Cerascreen
  class LabordatenbankClient
    @instance_mutex = Mutex.new
    attr_reader :connection

    private_class_method :new

    def initialize  	
    	@connection = Faraday.new(url: Rails.application.credentials.dig(:labordatenbank_api, :url)) do |f|
    		# f.response :raise_error # raise Faraday::Error on status code 4xx or 5xx
        f.request :json
        f.request :authorization, :basic, Rails.application.credentials.dig(:labordatenbank_api, :username), Rails.application.credentials.dig(:labordatenbank_api, :password)
        f.response :json
        f.adapter :net_http_persistent
        f.response :logger, Rails.logger, headers: true, log_level: :debug  
      end
    end

    class << self
      # define the singleton class' initialization
      def instance
        return @instance if @instance
        @instance_mutex.synchronize do
            @instance ||= new
        end
        return @instance
      end
    end

    def self.result_for(sample_code)
    	@connection.get("#{Rails.application.credentials.dig(:labordatenbank_api, :url)}/#{sample_code}")
    end
  	
  end
end


# class GetResultsJob < ApplicationJob
#   queue_as :default

#   def perform(current_patient)
#     @current_patient = current_patient

#     begin
#       connection = MasdiagApiClient.instance.connection      
#       # response = connection.get('/patient_portal/results', { pesel: "123456789012", email: "marcin.lukasik@onet.pl"})
#       response = connection.get('/patient_portal/results', { pesel: @current_patient.pesel, email: @current_patient.email})
#       create_results(response) 
#     rescue Faraday::Error => e
#       err = ["body: #{e.inspect}"]
#       pp(err)
#     end
#   end


# private

#   def create_results(response)
#     if response.body.is_a?(Array)
#       response.body.each do |r|
#         @current_patient.results.create(sample_code: r["sample_code"], authorization_date: r["authorization_date"], test_name: r["test_name"], raw_result: r["raw_result"], measurement_id: r["measurement_id"], url: r["url"])
#       end
#     else
#       pp "========================="
#       pp "GetResultsJob - response body is not an Array!!!"
#       pp response.body
#       pp "========================="      
#     end    
#   end

# end
