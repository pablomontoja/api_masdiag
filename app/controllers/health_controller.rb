class HealthController < ApplicationController

  def check
    render json: {status: "OK"}, status: :ok
  end

  def invalid
    raise ActiveRecord::RecordInvalid
  end

  def not_found
    raise ActiveRecord::RecordNotFound
  end
end
