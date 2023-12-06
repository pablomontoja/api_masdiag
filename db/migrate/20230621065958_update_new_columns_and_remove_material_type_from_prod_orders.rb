class UpdateNewColumnsAndRemoveMaterialTypeFromProdOrders < ActiveRecord::Migration[7.0]
  def change
    Product.where("ref LIKE ?", "%.URN.%").each{ |pr| pr.update(material_handler: :urine_vial)}
    Product.where("ref LIKE ?", "%DBS.T5.%").each{ |pr| pr.update(material_handler: :dbs_t5)}
    remove_column :production_orders, :material_type 
  end
end
