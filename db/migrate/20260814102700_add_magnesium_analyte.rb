class AddMagnesiumAnalyte < ActiveRecord::Migration[7.1]
  def change
    I18n.locale = :pl
    project = Project.find(45)
    project.update(
      WithCutter: true,                                             
      PlateDimensionX: 8,                                            
      PlateDimensionY: 12,                                           
      Prefix: nil,   
      is_blocked_online: false,
      is_active: true
    )

    analyte = Analyte.create!(
      Name: "Magnez",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/L",                                                
      NameInReport: "Magnez",                                          
      NameInAPI: "magnesium",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: :dbs
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 1.1,
      Max: 2.1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 1.1,
      AcceptableMax: 2.1
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 1.1,
      Max: 2.1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 1.1,
      AcceptableMax: 2.1
    )

    I18n.locale = :en
    analyte.reload.update(NameInReport: "Magnesium")

  end
end
