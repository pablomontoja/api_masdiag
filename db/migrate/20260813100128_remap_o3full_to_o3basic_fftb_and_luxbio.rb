class RemapO3fullToO3basicFftbAndLuxbio < ActiveRecord::Migration[7.1]
  def change
    ReservedTest.includes(reserved_sample_code: :sample).where(reserved_sample_code: { InstitutionId: 83 }).where(reserved_sample_code: { Samples: {Id: nil}}).where(project_id: 21).update_all(project_id: 34)
    ReservedTest.includes(reserved_sample_code: :sample).where(reserved_sample_code: { InstitutionId: 95 }).where(reserved_sample_code: { Samples: {Id: nil}}).where(project_id: 21).update_all(project_id: 34)
  end
end
