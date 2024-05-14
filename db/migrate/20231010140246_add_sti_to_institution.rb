class AddStiToInstitution < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions, :kind, :string, null: false, default: "Institution"
    add_column :institutions, :email_for_results, :string, null: true, default: nil    
  end
end


