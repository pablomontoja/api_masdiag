class AddMetalsInUrineToProjects < ActiveRecord::Migration[7.0]
  def change


    ActiveRecord::Base.transaction do
      project = Project.create!(                                                       
        Name: "Metale w moczu",                                     
        Description: "Metale w moczu",                   
        WithCutter: true,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Metale w moczu",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "zofia.mierzynska@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Metals in urine",
        is_active: true
      )


      # CREATININE
      analyte = Analyte.create!(
        Name: "Creatinine",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 1.1,                                                
        CutoffMax: 610,                                              
        Unit: "mg/dl",                                                
        NameInReport: "Creatinine",                                          
        NameInAPI: "kreatinin_iu",                                             
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
        Min: 40,
        Max: 278,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 40,
        AcceptableMax: 278,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 29,
        Max: 226,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 29,
        AcceptableMax: 226,
        MaterialType: 5
      )

      # ALUMINIUM
      analyte = Analyte.create!(
        Name: "Al 27 (Al Ni) Quant Average ug/L",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: true,                                 
        CutoffMin: 40,                                                
        CutoffMax: 2000,                                              
        Unit: "µg/g crea",                                                
        NameInReport: "Aluminium",
        NameInAPI: "aluminium",                                             
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
        Max: 60,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 60,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0,
        Max: 60,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 60,
        MaterialType: 5
      )


      # ARSENIC
      analyte = Analyte.create!(
        Name: "As 75 (As) Quant Average ug/L",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2,                                                
        CutoffMax: 200,                                              
        Unit: "µg/l",                                                
        NameInReport: "Arsenic",
        NameInAPI: "arsenic",                                             
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
        Max: 15,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 15,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0,
        Max: 15,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 15,
        MaterialType: 5
      )


      # CADMIUM
      analyte = Analyte.create!(
        Name: "Cd 111 (HgPbCdZ) Quant Average ug/L",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 0.5,                                                
        CutoffMax: 50,                                              
        Unit: "µg/l",                                                
        NameInReport: "Cadmium",
        NameInAPI: "cadmium",                                             
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
        Max: 0.8,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 0.8,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0,
        Max: 0.8,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 0.8,
        MaterialType: 5
      )



      # COBALT
      analyte = Analyte.create!(
        Name: "Co 59 (Co) Quant Average ug/L",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 0.5,                                                
        CutoffMax: 100,                                              
        Unit: "µg/l",                                                
        NameInReport: "Cobalt",
        NameInAPI: "cobalt",                                             
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
        Max: 1.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 1.0,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0,
        Max: 1.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 1.0,
        MaterialType: 5
      )


      # CHROMIUM
      analyte = Analyte.create!(
        Name: "Cr 52 (Cr) Quant Average ug/L",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 1,                                                
        CutoffMax: 100,                                              
        Unit: "µg/l",                                                
        NameInReport: "Chromium",
        NameInAPI: "chromium",                                             
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
        Max: 1.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 1.0,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0,
        Max: 1.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0,
        AcceptableMax: 1.0,
        MaterialType: 5
      )


      # COPPER
      analyte = Analyte.create!(
        Name: "Cu 63 (Cu) Quant Average ug/L",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 2,                                                
        CutoffMax: 200,                                              
        Unit: "µg/l",                                                
        NameInReport: "Copper",
        NameInAPI: "copper",                                             
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
        Min: 7.0,
        Max: 40.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 7.0,
        AcceptableMax: 40.0,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 7.0,
        Max: 40.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 7.0,
        AcceptableMax: 40.0,
        MaterialType: 5
      )


      # MERCURY
      analyte = Analyte.create!(
        Name: "Hg 202 (HgPbCdZ) Quant Average ug/L",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: true,                                 
        CutoffMin: 0.5,                                                
        CutoffMax: 50,                                              
        Unit: "µg/g crea",                                                
        NameInReport: "Copper",
        NameInAPI: "copper",                                             
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
        Max: 25,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 25,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 25,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 25,
        MaterialType: 5
      )


      # LEAD
      analyte = Analyte.create!(
        Name: "Pb Pb suma (HgPbCdZ) Quant Average ug/L",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 0.5,                                                
        CutoffMax: 100,                                              
        Unit: "µg/l",                                                
        NameInReport: "Lead",
        NameInAPI: "lead",                                             
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
        Max: 10.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10.0,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 10.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 10.0,
        MaterialType: 5
      )


      # ZINC
      analyte = Analyte.create!(
        Name: "Zn 66 (HgPbCdZ) Quant Average ug/L",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: true,                                 
        CutoffMin: 20,                                                
        CutoffMax: 2000,                                              
        Unit: "µg/g crea",                                                
        NameInReport: "Zinc",
        NameInAPI: "zinc",                                             
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
        Min: 250,
        Max: 1200,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 250,
        AcceptableMax: 1200,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 250,
        Max: 1200,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 250,
        AcceptableMax: 1200,
        MaterialType: 5
      )







    end











  end
end
