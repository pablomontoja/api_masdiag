class UpdateReservedByContractorIdForLalen < ActiveRecord::Migration[7.0]
  def change
    V1::Common::LALEN_INSTITUTION_IDS.each do |inst_id|
      cid = Contractor.where(institution_id: inst_id).find_by("first_name LIKE ?", "API%")&.Id
      ReservedSampleCode.where(IsRetailSale: true, InstitutionId: inst_id).update_all(reserved_by_contractor_id: cid)
      "cid: #{cid.to_s}"
    end
  end
end
