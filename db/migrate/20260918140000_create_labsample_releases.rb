class CreateLabsampleReleases < ActiveRecord::Migration[7.0]
  def change
    create_table :labsample_releases, charset: "utf8mb4" do |t|
      t.string :version, null: false
      t.timestamps
    end

    add_index :labsample_releases, :version, unique: true
  end
end
