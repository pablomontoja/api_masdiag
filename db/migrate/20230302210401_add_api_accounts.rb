class AddApiAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :api_accounts do |t|
      t.string :username
      t.string :password_digest
      t.integer :contractor_id, limit: 4

      t.timestamps
    end

    add_foreign_key :api_accounts, :Contractors, column: :contractor_id, primary_key: :Id
  end
end
