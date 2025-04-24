class AddArg1dProject < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.transaction do
      project = Project.create!(                                                       
        Name: "Deficyt arginazy",                                     
        Description: "Deficyt arginazy",                   
        WithCutter: true,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Deficyt arginazy",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "anna.krol@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Arginase deficiency",
        is_active: true
      )

      analyte = Analyte.create!(
        Name: "Arg",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 1,                                                
        CutoffMax: 806.5,                                              
        Unit: "nmol/mL",                                                
        NameInReport: "Arginina",                                          
        NameInAPI: "arginine",                                             
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
        Min: 3.7,
        Max: 50,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 3.7,
        AcceptableMax: 50,
        MaterialType: 0
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 3.7,
        Max: 50,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 3.7,
        AcceptableMax: 50,
        MaterialType: 0
      )

      analyte = Analyte.create!(
        Name: "Orn",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2,                                                
        CutoffMax: 806.5,                                              
        Unit: "nmol/mL",                                                
        NameInReport: "Ornityna",                                          
        NameInAPI: "ornithine",                                             
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
        Min: 44,
        Max: 135,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 44,
        AcceptableMax: 135,
        MaterialType: 0
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 44,
        Max: 135,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 44,
        AcceptableMax: 135,
        MaterialType: 0
      )


      analyte = Analyte.create!(
        Name: "Arg/Orn",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: true,                                 
        CutoffMin: 0.01,                                                
        CutoffMax: 403.25,                                              
        Unit: nil,                                                
        NameInReport: "Arginina/Ornityna",                                          
        NameInAPI: "arginine/ornithine",                                             
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
        Min: 0.06,
        Max: 0.64,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.06,
        AcceptableMax: 0.64,
        MaterialType: 0
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.06,
        Max: 0.64,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.06,
        AcceptableMax: 0.64,
        MaterialType: 0
      )

    end
  end
end
