module LalenCheck
  extend ActiveSupport::Concern

  included do
    before_action :only_lalen_access

    def lalen_institution_ids
    	[85, 89, 93]
    end
  end

  private

  def only_lalen_access
    if !lalen_institution_ids.include?(Current.api_account.institution.id)
      json_response({ message: "You do not have access to this part of Masdiag API." }, :unprocessable_entity)
    end
  end

end