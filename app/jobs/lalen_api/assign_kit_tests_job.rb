module LalenApi
  class AssignKitTestsJob < ApplicationJob
    # This job POSTs an assignment to an external partner and retries on failure, so it
    # must never run for a write that was rolled back — the partner cannot be untold.
    # Declared per-job rather than through config.active_job.enqueue_after_transaction_commit,
    # which Rails 8.0 deprecates and removes in 8.1. Stating it here keeps the guarantee
    # attached to the job that needs it, where a defaults change cannot silently drop it.
    self.enqueue_after_transaction_commit = true

    retry_on StandardError, wait: :polynomially_longer, attempts: 10 do |job, error|
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
