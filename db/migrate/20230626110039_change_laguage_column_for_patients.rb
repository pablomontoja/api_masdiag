class ChangeLaguageColumnForPatients < ActiveRecord::Migration[7.0]
  def change
    # change_column :Patients, :language, :string, default: "pl", null: false
    # add_column :api_accounts, :language, :string, default: "pl", null: false

    # Patient.update_all(language: "pl")
    # Patient.where(ContractorId: 125).update_all(language: "de")
    # Patient.where(ContractorId: 447).update_all(language: "de")
    # Patient.where(ContractorId: 638).update_all(language: "de")
  end
end
