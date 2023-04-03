class AddEngNameToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :Projects, :eng_name, :string
  end
end
