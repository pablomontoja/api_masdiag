class AddIodineToProjects < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.transaction do
      eag = Analyte.create!(
        Name: "EAG",                                                  
        ProjectId: 23,                                                 
        IsCalculatedFromOthers: true,                           
        CutoffMin: 0,                                                
        CutoffMax: 100000,                                              
        Unit: "mmol/L",                                                
        NameInReport: "Estimated Average Glucose",                                          
        NameInAPI: "eag",                                             
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
        Min: 3.89,
        Max: 7.0,
        AnalyteId: eag.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 3.89,
        AcceptableMax: 7.0,
        MaterialType: 0
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 3.89,
        Max: 7.0,
        AnalyteId: eag.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 3.89,
        AcceptableMax: 7.0,
        MaterialType: 0
      )

      # AnalyteResult.where(AnalyteId: 322).each do |ar|
      #   duplicate = ar.dup
      #   duplicate.MeasuredValue = (1.59 * ar.MeasuredValue) - 2.59
      #   duplicate.Value = duplicate.MeasuredValue
      #   duplicate.AnalyteId = eag.Id
      #   duplicate.Unit = "mmol/L"
      #   duplicate.save
      # end
    end




    ActiveRecord::Base.transaction do
      project = Project.create!(                                                       
        Name: "Jod w moczu",                                     
        Description: "Jod w moczu",                   
        WithCutter: true,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Jod w moczu",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "zofia.mierzynska@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Iodine in urine",
        is_active: true
      )

      analyte = Analyte.create!(
        Name: "Iodine",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 1,                                                
        CutoffMax: 1000,                                              
        Unit: "ug/g creatinine",                                                
        NameInReport: "Iodine",                                          
        NameInAPI: "jod_krea_iu",                                             
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
        Min: 50,
        Max: 300,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 100,
        AcceptableMax: 200,
        MaterialType: 5
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 50,
        Max: 300,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 100,
        AcceptableMax: 200,
        MaterialType: 5
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

    end

  end
end

