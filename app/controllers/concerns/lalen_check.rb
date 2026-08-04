module LalenCheck
  extend ActiveSupport::Concern

  included do
    before_action :only_lalen_access
  end

  private

  def only_lalen_access
    if !V1::Common::LALEN_INSTITUTION_IDS.include?(Current.api_account.institution.id)
      json_response({ message: "You do not have access to this part of Masdiag API." }, :unprocessable_content)
    end
  end

end