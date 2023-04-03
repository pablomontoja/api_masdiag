class V1::CommonController < ApplicationController

  def identity_documents
    render json: V1::Common::IDENTITY_DOCUMENTS
  end

  def api_version
    render json: {version: V1::Common::CURRENT_VERSION, documentation_url: V1::Common::CURRENT_DOCUMENTATION_URL}
  end

  def tests
    # projects = Project.where(id: [2, 3, 10, 12, 13, 14, 15, 16, 17, 18, 19]).map { |pr| {id: pr.Id, name: pr.eng_name} }
    tests = {tests: V1::Common::AVAILABLE_TESTS}
    json_response(tests)
  end

end
