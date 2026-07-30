module LalenApi
	class Client
	  @instance_mutex = Mutex.new
	  attr_reader :connection

	  private_class_method :new

	  def initialize  	
	  	@connection = Faraday.new(url: Rails.application.credentials.dig(:lalenportalapi, :url)) do |f|
	  		# f.response :raise_error # raise Faraday::Error on status code 4xx or 5xx
	      f.request :json
	      f.request :authorization, :basic, Rails.application.credentials.dig(:lalenportalapi, :username), Rails.application.credentials.dig(:lalenportalapi, :password)
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

	  # def results
	  # 	@connection.get('/patient_portal/results', { pesel: "123456789012", email: "marcin.lukasik@onet.pl"})  	
	  # end
		
	end
end