class AddAettingsToApiAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :api_accounts, :settings, :text
  end
end
