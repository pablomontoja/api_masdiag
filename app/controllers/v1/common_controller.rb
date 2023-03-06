class V1::CommonController < ApplicationController

  def identity_documents
    render json: V1::Common::IDENTITY_DOCUMENTS
  end

end
