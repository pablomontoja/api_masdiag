class AddGoldcupToxoProject < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.transaction do
      project = Project.create!(                                                       
        Name: "Goldcup TOX",                                     
        Description: "Goldcup TOX",                   
        WithCutter: true,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Goldcup TOX",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "toxo@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Goldcup TOX",
        is_active: true
      )

      analyte = Analyte.create!(
        Name: "Amfetamina 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Amfetamina",                                          
        NameInAPI: "amphetamine",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "MDA 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "3,4-metylenodioksyamfetamina",                                          
        NameInAPI: "3,4-methylenedioxyamphetamine",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Morfina 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 10,                                                
        CutoffMax: 800,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Morfina",                                          
        NameInAPI: "morphine",                                             
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
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Kodeina 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 10,                                                
        CutoffMax: 800,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Kodeina",                                          
        NameInAPI: "codeine",                                             
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
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Metamfetamina 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Metamfetamina",                                          
        NameInAPI: "methamphetamine",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "MDMA 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "3,4-Metylenodioksymetamfetamina",                                          
        NameInAPI: "3,4-methylenedioxymethamphetamine",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "MDEA 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "3,4-etylenodioksymetamfetamina",                                          
        NameInAPI: "3,4-methylenedioxy-n-ethylamphetamine",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "6-Acetylomorfina 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 10,                                                
        CutoffMax: 800,                                              
        Unit: "ng/ml",                                                
        NameInReport: "6-mono-acetylo-morfina",                                          
        NameInAPI: "6-acetylmorphine",                                             
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
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Tramadol 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 50,                                                
        CutoffMax: 4000,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Tramadol",                                          
        NameInAPI: "tramadol",                                             
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
        Min: 0.0,
        Max: 50,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 50,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 50,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 50,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Benzoiloekgonina 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 50,                                                
        CutoffMax: 4000,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Benzoiloekgonina",                                          
        NameInAPI: "benzoylecgonine",                                             
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
        Min: 0.0,
        Max: 50,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 50,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 50,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 50,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Kokaina 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 10,                                                
        CutoffMax: 800,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Kokaina",                                          
        NameInAPI: "cocaine",                                             
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
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Klonazepam 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 10,                                                
        CutoffMax: 800,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Klonazepam",                                          
        NameInAPI: "clonazepam",                                             
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
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "7-aminoklonazapam 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 10,                                                
        CutoffMax: 800,                                              
        Unit: "ng/ml",                                                
        NameInReport: "7-Aminoklonazapam",                                          
        NameInAPI: "7-aminoclonazepam",                                             
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
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Flunitrazepam 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2,                                                
        CutoffMax: 160,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Flunitrazepam",                                          
        NameInAPI: "flunitrazepam",                                             
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
        Min: 0.0,
        Max: 2,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 2,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Fentanyl 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 0.2,                                                
        CutoffMax: 16,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Fentanyl",                                          
        NameInAPI: "fentanyl",                                             
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
        Min: 0.0,
        Max: 0.2,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 0.2,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 0.2,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 0.2,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "7-aminoflunitrazepam 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2,                                                
        CutoffMax: 160,                                              
        Unit: "ng/ml",                                                
        NameInReport: "7-aminoflunitrazepam",                                          
        NameInAPI: "7-aminoflunitrazepam",                                             
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
        Min: 0.0,
        Max: 2,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 2,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Zolpidem 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Zolpidem",                                          
        NameInAPI: "zolpidem",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Lorazepam 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 10,                                                
        CutoffMax: 800,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Lorazepam",                                          
        NameInAPI: "lorazepam",                                             
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
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 10,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Hydroksyzyna 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 5,                                                
        CutoffMax: 400,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Hydroksyzyna 1",                                          
        NameInAPI: "hydroxyzine",                                             
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
        Min: 0.0,
        Max: 5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 5,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 5,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Nordiazepam 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Nordiazepam",                                          
        NameInAPI: "nordiazepam",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Oksazepam 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 50,                                                
        CutoffMax: 4000,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Oksazepam",                                          
        NameInAPI: "oxazepam",                                             
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
        Min: 0.0,
        Max: 50,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 50,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 50,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 50,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Metadon 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Metadon",                                          
        NameInAPI: "methadone",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Diazepam 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Diazepam",                                          
        NameInAPI: "diazepam",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Alprazolam 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2,                                                
        CutoffMax: 160,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Alprazolam",                                          
        NameInAPI: "alprazolam",                                             
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
        Min: 0.0,
        Max: 2,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 2,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Oxycodon 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2.5,                                                
        CutoffMax: 200,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Oksykodon",                                          
        NameInAPI: "oxycodone",                                             
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
        Min: 0.0,
        Max: 2.5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2.5,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 2.5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2.5,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "Oxymorfon 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2.5,                                                
        CutoffMax: 200,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Oksymorfon",                                          
        NameInAPI: "oxymorphone",                                             
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
        Min: 0.0,
        Max: 2.5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2.5,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 2.5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2.5,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "noroxycodon 1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2.5,                                                
        CutoffMax: 200,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Noroksykodon",                                          
        NameInAPI: "noroxycodone",                                             
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
        Min: 0.0,
        Max: 2.5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2.5,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 2.5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2.5,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "di-H-CMC_1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 20,                                                
        CutoffMax: 1600,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Diwodorochlorometkatynon",                                          
        NameInAPI: "dihydrochloromethcathinone",                                             
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
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "THC_m",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2.5,                                                
        CutoffMax: 80,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Tetrahydrokannabinol (delta-9THC)",                                          
        NameInAPI: "delta9-tetrahydrocannabinol (delta-9thc)",                                             
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
        Min: 0.0,
        Max: 2.5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2.5,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 2.5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 2.5,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "CBD_m",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 1,                                                
        CutoffMax: 80,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Kannabidiol (CBD)",                                          
        NameInAPI: "cannabidiol (cbd)",                                             
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
        Min: 0.0,
        Max: 1,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 1,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 1,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 1,
        MaterialType: 9
      )

      analyte = Analyte.create!(
        Name: "THCCOOH_m",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 5,                                                
        CutoffMax: 400,                                              
        Unit: "ng/ml",                                                
        NameInReport: "11-karboksy-delta9-tetrahydrokannabinol",                                          
        NameInAPI: "11-nor-9-carboxy-delta9-tetrahydrocannabinol",                                             
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
        Min: 0.0,
        Max: 5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 5,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 5,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 5,
        MaterialType: 9
      )

















    end
  end
end
