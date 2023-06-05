class AddLockBoxToApiAccountSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :api_accounts, :settings_ciphertext, :text
  end
end
