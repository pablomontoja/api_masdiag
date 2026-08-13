class RemapO3fullToO3basicFftbAndLuxbio < ActiveRecord::Migration[7.1]
  NEEDED_ANALYTES = ["cis-mono-unsaturated-sum", "C16:1n7", "C18:1n9", "C20:1n9", "C24:1n9"]
  NOT_REQUIRED = ["palmitate_index", "omega3_score", "prenatal_dha", "omega3_score", "palmitate_index", "prenatal_dha"]

  def change
    Analyte.where(NameInAPI: NEEDED_ANALYTES).where(ProjectId: 21).each do |analyte|
      new_o3i = analyte.dup
      new_o3i.ProjectId = 34

      if new_o3i.save
        analyte.analyte_ranges.each do |ar|
          ar_dup = ar.dup
          ar_dup.AnalyteId = new_o3i.Id
          ar_dup.save
        end
      else
        pp new_o3i.errors
      end
    end

    Analyte.where.not(NameInAPI: NOT_REQUIRED).where(ProjectId: 34).update_all(is_required: true)

    ReservedTest.includes(reserved_sample_code: :sample).where(reserved_sample_code: { InstitutionId: 83 }).where(reserved_sample_code: { Samples: {Id: nil}}).where(project_id: 21).update_all(project_id: 34)
    ReservedTest.includes(reserved_sample_code: :sample).where(reserved_sample_code: { InstitutionId: 95 }).where(reserved_sample_code: { Samples: {Id: nil}}).where(project_id: 21).update_all(project_id: 34)
  end
end
