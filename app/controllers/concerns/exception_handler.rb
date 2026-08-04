module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |e|
      Sentry.capture_exception(e)
      json_response({ message: e.message }, :not_found)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      Sentry.capture_exception(e)
      json_response({ message: e.message }, :unprocessable_content)
    end
  end

end
