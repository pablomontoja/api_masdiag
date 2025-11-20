class ChangeCodeToStringAndAddIndexInReservedSampleCodes < ActiveRecord::Migration[7.0]
  def change
    ReservedSampleCode.find(16014).destroy
    change_column :ReservedSampleCodes, :Code, :string, limit: 50
    add_index :ReservedSampleCodes, :Code, unique: true

    add_column :Samples, :reserved_sample_code_id, :integer
    add_index :Samples, :reserved_sample_code_id, name: "index_Samples_on_reserved_sample_code_id"
    
    execute <<-SQL
      UPDATE Samples s
      INNER JOIN ReservedSampleCodes rsc ON s.Code = rsc.Code
      SET s.reserved_sample_code_id = rsc.Id
    SQL
    
    # Add foreign key constraint
    add_foreign_key :Samples, :ReservedSampleCodes, 
                    column: :reserved_sample_code_id, 
                    primary_key: "Id",
                    name: "fk_samples_reserved_sample_codes"

    add_reference :packages, :shop_order, foreign_key: true, index: true

    ShopOrder.find_each do |shop_order|
      next if shop_order.package_ids.blank?
      next if shop_order.package_ids == "-"
      
      shop_order.package_ids.each do |package_id|
        package = Package.find_by(id: package_id)
        if package
          package.update_column(:shop_order_id, shop_order.id)
        else
          puts "Warning: Package with id #{package_id} not found for ShopOrder ##{shop_order.id}"
        end
      end
    end

    add_column :institutions, :email_for_notifications, :string, null: true, default: nil
    add_column :institutions, :short_name, :string, null: true, default: nil
  end
end
