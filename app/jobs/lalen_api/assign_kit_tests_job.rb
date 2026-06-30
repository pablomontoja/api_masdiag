module LalenApi
  class AssignKitTestsJob < ApplicationJob
    retry_on StandardError, wait: :exponentially_longer, attempts: 10 do |job, error|
      Sentry.capture_exception(error)
    end

    def perform(barcode, api_keys)
      begin
        kit_tests = LalenApi::KitTests.new(barcode: barcode, tests: api_keys)
        raise LalenApi::Error.new("Invalid KitTests payload for ApiMasdiagCom") unless kit_tests.valid?

        connection = LalenApi::Client.instance.connection
        response = connection.post('kit_tests', kit_tests.as_json, "Content-Type" => "application/json")
        pp response
        return if response.status == 404
        raise LalenApi::Error.new("Problems with Kit Tests Assignment on ApiMasdiagCom") if response.status != 201
      rescue StandardError => e
        Sentry.capture_exception(e)
        raise e
      end
    end
  end
end
