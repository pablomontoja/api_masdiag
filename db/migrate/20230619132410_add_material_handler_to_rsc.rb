class AddMaterialHandlerToRsc < ActiveRecord::Migration[7.0]
  def change
    add_column :ReservedSampleCodes, :material_handler, :integer, default: 0, null: false
    add_column :products, :material_type, :integer, default: 0, null: false
    add_column :products, :material_handler, :integer, default: 0, null: false
  end
end
