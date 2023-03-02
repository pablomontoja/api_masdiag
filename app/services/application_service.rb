class ApplicationService

  def self.call(*args, &block)
    new(*args, &block).call
  end

private

  def handle_result(result = nil)
    OpenStruct.new({success?: true, payload: result})
  end

  def handle_error(error = [])
    OpenStruct.new({success?: false, error: error})
  end
  
end