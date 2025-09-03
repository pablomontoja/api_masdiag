class UpdateAldxAnalytes < ActiveRecord::Migration[7.0]
  def change
    remove_column :AnalyteRanges, :MaterialType
    
    Analyte.find(423).update(NameInReport: "C26:0-LPC*")
    Analyte.find(424).update(NameInReport: "C24:0-LPC**")
    Analyte.find(425).update(NameInReport: "C22:0-LPC***")

    Analyte.find(426).update(NameInReport: "C26:0-LPC / C24:0-LPC")
    Analyte.find(427).update(NameInReport: "C26:0-LPC / C22:0-LPC")
    Analyte.find(428).update(NameInReport: "C24:0-LPC / C22:0-LPC")

    AnalyteRange.where(AnalyteId: (423..428)).each do |ar|
      ar.update(Max: ar.Max.round(2), AcceptableMax: ar.AcceptableMax.round(2))
    end


    # OMEGA BASIC ANALYTES COPY
    Analyte.where(NameInAPI: "index-omega-3", ProjectId: 21).each do |analyte|
      new_o3i = analyte.dup
      new_o3i.ProjectId = 34
      new_o3i.save

      analyte.analyte_ranges.each do |ar|
        ar_dup = ar.dup
        ar_dup.AnalyteId = new_o3i.Id
        ar_dup.save
      end      
    end


  end
end
