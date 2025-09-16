class AddOmegaBasicAnalytes < ActiveRecord::Migration[7.0]
  EXCLUDED_ANALYTES = ["cis-mono-unsaturated-sum", "C16:1n7", "C18:1n9", "C20:1n9", "C24:1n9", "trans-sum", "C16:1n7t", "C18:1t", "C18:2n6t", "index-trans"]

  def change
    remove_column :AnalyteRanges, :AgeFromMonth
    remove_column :AnalyteRanges, :AgeToMonth
    AnalyteRange.reset_column_information

    Analyte.where.not(NameInAPI: EXCLUDED_ANALYTES).where(ProjectId: 21).each do |analyte|
      new_o3i = analyte.dup
      new_o3i.ProjectId = 34
      new_o3i.is_required = new_o3i.NameInAPI == "index-omega-3" ? true : false

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

  end

end