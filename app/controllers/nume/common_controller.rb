class Nume::CommonController < ApplicationController
  include NumeCheck

  def identity_documents
    render json: V1::Common::IDENTITY_DOCUMENTS
  end

  def version
    render json: {version: V1::Common::CURRENT_VERSION, documentation_url: V1::Common::CURRENT_DOCUMENTATION_URL}
  end
end
