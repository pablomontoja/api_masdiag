class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def is_integer(string)
    true if Integer string
    
    rescue StandardError => e
      Sentry.capture_exception(e)
      false
  end
end
