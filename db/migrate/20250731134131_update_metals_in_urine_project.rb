class UpdateMetalsInUrineProject < ActiveRecord::Migration[7.0]
  def change
    current_crea_normalized = Analyte.where(Id: [402, 408, 410])
    current_crea_normalized.update_all(Unit: "µg/l", IsCalculatedFromOthers: false)

    Analyte.where(Id: 402..410).each do |a|
      duplicate = a.dup
      duplicate.Unit = "µg/g crea"
      duplicate.Name = a.Name.gsub("Quant Average ug/L", "µg/g crea")
      duplicate.IsCalculatedFromOthers = true
      duplicate.NameInReport = a.NameInReport + " crea normalized"
      duplicate.NameInAPI = a.NameInAPI + "_crea" 
      duplicate.save

      a.analyte_ranges.each do |range|
        range_dup = range.dup
        range_dup.AnalyteId = duplicate.Id
        range_dup.save
      end
    end

    project = Project.find(32)

    # NICKEL
    analyte = Analyte.create!(
      Name: "Ni 60 (Al Ni) Quant Average ug/L",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 6,                                                
      CutoffMax: 200,                                              
      Unit: "µg/L",                                                
      NameInReport: "Nickel",
      NameInAPI: "nickel",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 6,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 6,
      MaterialType: 5
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 6,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 6,
      MaterialType: 5
    )

    duplicate_ni = analyte.dup
    duplicate_ni.Unit = "µg/g crea"
    duplicate_ni.Name = analyte.Name.gsub("Quant Average ug/L", "µg/g crea")
    duplicate_ni.IsCalculatedFromOthers = true
    duplicate_ni.NameInReport = analyte.NameInReport + " crea normalized"
    duplicate_ni.NameInAPI = analyte.NameInAPI + "_crea" 
    duplicate_ni.save

    analyte.analyte_ranges.each do |range|
      range_dup = range.dup
      range_dup.AnalyteId = duplicate_ni.Id
      range_dup.save
    end

  end
end
