# TOXO app migrations
class CreateSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :sessions do |t|
      # Celowo snake_case – to nowa tabela, nie dziedziczona z C#
      # Jawnie integer – Contractors.Id to int(11), t.references tworzyłby bigint
      t.integer :contractor_id, null: false
      t.string :ip_address
      t.string :user_agent
      t.string :token, null: false
      t.datetime :last_active_at

      t.timestamps
    end

    add_index :sessions, :token, unique: true
    add_index :sessions, :contractor_id
    add_foreign_key :sessions, :Contractors, column: :contractor_id, primary_key: :Id
  end
end
