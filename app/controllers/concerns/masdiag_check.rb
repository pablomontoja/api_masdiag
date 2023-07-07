module MasdiagCheck
  extend ActiveSupport::Concern

  included do
    before_action :only_masdiag_access
  end

  private

  def only_masdiag_access
    if Current.api_account.institution.id != 1
      json_response({ message: "You do not have access to this part of Masdiag API." }, :unprocessable_entity)
    end
  end

end
