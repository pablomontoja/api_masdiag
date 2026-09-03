class AddPagnProject < ActiveRecord::Migration[7.2]
  def change
    I18n.locale = :pl

    project = Project.create!(                                                                                                                  
            Name: "PAGN",                                                                                                 
            Description: "PAGN",                                                                                          
            WithCutter: true,                                                                                                                   
            PlateDimensionX: 8,                                                                                                                 
            PlateDimensionY: 12,                                                                                                                
            Prefix: nil,                                                                                                                        
            created_at: Time.now,                                                                                                               
            updated_at: Time.now,                                                                                                               
            is_blocked_online: false,                                                                                                           
            survey_description: ".",                                                                                                            
            PdfNameOfAnalysis: "PAGN",                        
            PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
            product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
            pkwiu_in_invoice: "86.90.15",
            brutto_price: 0.5e2,
            FinalProtocoleHeader: nil,
            responsible_person_email: "malgorzata.rogozinska@masdiag.pl",
            has_selectable_analytes: false,
            InjectionVolume: 0.22e2,
            eng_name: "PAGN",
            is_active: true
          )

    analyte = Analyte.create!(
      Name: "PBA 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "µg/mL",                                                
      NameInReport: "Kwas fenylomasłowy (PBA)",                                          
      NameInAPI: "pba",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: :blood_plasma
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1
    )

    I18n.locale = :en
    analyte.reload.update(NameInReport: "Phenylbutyric acid (PBA)")
    I18n.locale = :pl

    analyte = Analyte.create!(
      Name: "PAA 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "µg/mL",                                                
      NameInReport: "Kwas fenylooctowy (PAA)",                                          
      NameInAPI: "paa",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: :blood_plasma
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1
    )

    I18n.locale = :en
    analyte.reload.update(NameInReport: "Phenylacetic acid (PAA)")
    I18n.locale = :pl


    analyte = Analyte.create!(
      Name: "PAGN 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "µg/mL",                                                
      NameInReport: "Fenyloacetyloglutamina (PAGN)",                                          
      NameInAPI: "pagn",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: :blood_plasma
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1
    )

    I18n.locale = :en
    analyte.reload.update(NameInReport: "Phenylacetylglutamine (PAGN)")
    I18n.locale = :pl


    ##############################

    project = Project.create!(                                                                                                                  
            Name: "PAGN w moczu",                                                                                                 
            Description: "PAGN w moczu",                                                                                          
            WithCutter: true,                                                                                                                   
            PlateDimensionX: 8,                                                                                                                 
            PlateDimensionY: 12,                                                                                                                
            Prefix: nil,                                                                                                                        
            created_at: Time.now,                                                                                                               
            updated_at: Time.now,                                                                                                               
            is_blocked_online: false,                                                                                                           
            survey_description: ".",                                                                                                            
            PdfNameOfAnalysis: "PAGN w moczu",                        
            PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
            product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
            pkwiu_in_invoice: "86.90.15",
            brutto_price: 0.5e2,
            FinalProtocoleHeader: nil,
            responsible_person_email: "malgorzata.rogozinska@masdiag.pl",
            has_selectable_analytes: false,
            InjectionVolume: 0.22e2,
            eng_name: "PAGN in urine",
            is_active: true
          )

    analyte = Analyte.create!(
      Name: "PAGN 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: true,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Fenyloacetyloglutamina (PAGN)",                                          
      NameInAPI: "pagn",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: :urine
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 1,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 1,
      AcceptableMin: 0,
      AcceptableMax: 1
    )

    I18n.locale = :en
    analyte.reload.update(NameInReport: "Phenylacetylglutamine (PAGN)")
    I18n.locale = :pl

    # CREATININE
    analyte = Analyte.create!(
      Name: "Creatinine",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0.1,                                                
      CutoffMax: 40.0,                                              
      Unit: "mmol/L",                                                
      NameInReport: "Kreatynina",                                          
      NameInAPI: "crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: :urine
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 0,
      Min: 3.54,
      Max: 24.6,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 3.54,
      AcceptableMax: 24.6
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 150,
      Gender: 1,
      Min: 2.55,
      Max: 20.0,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 2.55,
      AcceptableMax: 20.0
    )

    I18n.locale = :en
    analyte.reload.update(NameInReport: "Creatinine")
    I18n.locale = :pl


  end
end
