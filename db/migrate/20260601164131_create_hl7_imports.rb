class CreateHl7Imports < ActiveRecord::Migration[7.0]
  def change
    create_table :hl7_imports do |t|
      t.integer :measurement_id

      t.string  :s3_key,    null: false
      t.string  :s3_bucket
      t.string  :s3_etag
      t.integer :file_size

      t.string   :control_id
      t.string   :message_type
      t.datetime :message_datetime
      t.string   :sending_application
      t.string   :sending_facility
      t.string   :external_order_id
      t.string   :hl7_test_code
      t.string   :kit_code_extracted

      t.integer  :status,       null: false, default: 0
      t.datetime :processed_at
      t.text     :error_message
      t.text     :processing_stats
      t.integer  :retry_count,  default: 0
      t.datetime :last_retry_at

      t.timestamps
    end

    add_index :hl7_imports, :s3_key,              unique: true
    add_index :hl7_imports, :measurement_id,      unique: true
    add_index :hl7_imports, :status
    add_index :hl7_imports, :kit_code_extracted
    add_index :hl7_imports, :created_at

    add_foreign_key :hl7_imports, "Measurements", column: :measurement_id, primary_key: "Id"
  end
end
