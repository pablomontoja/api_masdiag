# TOXO app migrations
class AddToxoFieldsToSamples < ActiveRecord::Migration[7.0]
  def change
    # Data wysyłki materiału przez Contractora – odrębna od sample_collection_date
    add_column :Samples, :dispatch_date,              :datetime

    # Pola toksykologiczne
    add_column :Samples, :post_examination_procedure, :integer, default: 0, null: false
    add_column :Samples, :infectious_risk,            :integer, default: 0, null: false
    add_column :Samples, :execution_mode,             :integer, default: 0, null: false

    # add_index :Samples, :post_examination_procedure
    # add_index :Samples, :dispatch_date

    remove_column(:Samples, :UnsatisfactoryMaterialQuality, if_exists: true)
    remove_column(:Samples, :ProtocolIdOld, if_exists: true)
    remove_column(:Samples, :institution_custom_cbx, if_exists: true)
  end
end
