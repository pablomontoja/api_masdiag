class CreateScannedDocs < ActiveRecord::Migration[7.0]
  def change
    create_table :scanned_docs, charset: "utf8mb4" do |t|
      t.string   :source_filename, null: false
      t.string   :page_checksum,   null: false, limit: 64
      t.string   :document_key
      t.integer  :status,          null: false, default: 0
      t.string   :source,          null: false, default: "scan_watcher"
      t.integer  :sample_id
      t.datetime :captured_at
      t.datetime :received_at
      t.datetime :ocr_started_at
      t.datetime :transcribed_at
      t.text     :processing_error
      t.timestamps
    end

    add_index :scanned_docs, :page_checksum, unique: true
    add_index :scanned_docs, :status
    add_index :scanned_docs, :sample_id

    add_foreign_key :scanned_docs, "Samples", column: :sample_id, primary_key: "Id"
  end
end
