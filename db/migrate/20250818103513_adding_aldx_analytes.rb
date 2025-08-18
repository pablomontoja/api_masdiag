class AddingAldxAnalytes < ActiveRecord::Migration[7.0]
  def change
    change_column :Analytes, :CutoffMin, :decimal, precision: 11, scale: 4
    change_column :Analytes, :CutoffMax, :decimal, precision: 11, scale: 4
    change_column :AnalyteResults, :Value, :decimal, precision: 20, scale: 4

    change_column :AnalyteRanges, :Min, :decimal, precision: 20, scale: 4
    change_column :AnalyteRanges, :Max, :decimal, precision: 20, scale: 4
    change_column :AnalyteRanges, :AcceptableMin, :decimal, precision: 20, scale: 4
    change_column :AnalyteRanges, :AcceptableMax, :decimal, precision: 20, scale: 4


    project = Project.find(33)
    project.update(
      WithCutter: true,                                             
      PlateDimensionX: 8,                                            
      PlateDimensionY: 12,                                           
      Prefix: nil,   
      is_blocked_online: false,
      is_active: true
    )

    # LPC 26:0"
    analyte = Analyte.create!(
      Name: "LPC 26:0",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0.0159,                                                
      CutoffMax: 0.634,                                              
      Unit: "µmol/L",                                                
      NameInReport: "LPC 26:0",                                          
      NameInAPI: "lysophosphatidylcholine26:0",                                             
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
      Max: 0.167,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 0.167,
      MaterialType: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 0.167,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 0.167,
      MaterialType: 0
    )


    # LPC 24:0"
    analyte = Analyte.create!(
      Name: "LPC 24:0",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0.0332,                                                
      CutoffMax: 1.33,                                              
      Unit: "µmol/L",                                                
      NameInReport: "LPC 24:0",                                          
      NameInAPI: "lysophosphatidylcholine24:0",                                             
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
      Max: 0.333,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 0.333,
      MaterialType: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 0.333,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 0.333,
      MaterialType: 0
    )



    # LPC 22:0"
    analyte = Analyte.create!(
      Name: "LPC 22:0",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0.0174,                                                
      CutoffMax: 0.696,                                              
      Unit: "µmol/L",                                                
      NameInReport: "LPC 22:0",                                          
      NameInAPI: "lysophosphatidylcholine22:0",                                             
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
      Max: 0.218,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 0.218,
      MaterialType: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 0.218,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 0.218,
      MaterialType: 0
    )



    # LPC 26:0 / LPC 24:0"
    analyte = Analyte.create!(
      Name: "LPC 26:0 / LPC 24:0",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: nil,                                                
      CutoffMax: nil,                                              
      Unit: "",                                                
      NameInReport: "LPC 26:0 / LPC 24:0",                                          
      NameInAPI: "lpc26_lpc24_ratio",                                             
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
      Max: 0.786,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 0.786,
      MaterialType: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 0.786,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 0.786,
      MaterialType: 0
    )


    # LPC 26:0 / LPC 22:0"
    analyte = Analyte.create!(
      Name: "LPC 26:0 / LPC 22:0",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: nil,                                                
      CutoffMax: nil,                                              
      Unit: "",                                                
      NameInReport: "LPC 26:0 / LPC 22:0",                                          
      NameInAPI: "lpc26_lpc22_ratio",                                             
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
      Max: 1.74,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1.74,
      MaterialType: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 1.74,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1.74,
      MaterialType: 0
    )


    # LPC 24:0 / LPC 22:0"
    analyte = Analyte.create!(
      Name: "LPC 24:0 / LPC 22:0",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: nil,                                                
      CutoffMax: nil,                                              
      Unit: "",                                                
      NameInReport: "LPC 24:0 / LPC 22:0",                                          
      NameInAPI: "lpc24_lpc22_ratio",                                             
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
      Max: 2.68,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 2.68,
      MaterialType: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 2.68,
      AnalyteId: analyte.Id,
      AgeFromMonth: 0,
      AgeToMonth: 0,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 2.68,
      MaterialType: 0
    )



  end
end
