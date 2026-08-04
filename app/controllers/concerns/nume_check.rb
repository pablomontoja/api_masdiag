module NumeCheck
  extend ActiveSupport::Concern

  included do
    before_action :only_nume_access
  end

  private

  def only_nume_access
    if !Current.api_account.institution.name.include?("Nume")
      json_response({ message: "You do not have access to this part of Masdiag API." }, :unprocessable_content)
    end
  end

end
