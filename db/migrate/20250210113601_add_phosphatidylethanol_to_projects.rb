class AddPhosphatidylethanolToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :Projects, :is_active, :boolean, default: true, null: false

    ActiveRecord::Base.transaction do
      project = Project.create!(                                                       
        Name: "PEth - Fosfatydyloetanol",                                     
        Description: "Fosfatydyloetanol (16:0-18:1)",                   
        WithCutter: true,                                             
        PlateDimensionX: 8,                                            
        PlateDimensionY: 12,                                           
        Prefix: nil,                                                   
        created_at: Time.now,    
        updated_at: Time.now,    
        is_blocked_online: false,                                      
        survey_description: ".",                                       
        PdfNameOfAnalysis: "Fosfatydyloetanol",                        
        PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
        product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
        pkwiu_in_invoice: "86.90.15",
        brutto_price: 0.5e2,
        FinalProtocoleHeader: nil,
        responsible_person_email: "toxo@masdiag.pl",
        has_selectable_analytes: false,
        InjectionVolume: 0.22e2,
        eng_name: "Phosphatidylethanol",
        is_active: true
      )

      analyte = Analyte.create!(
        Name: "PEth 16:0-18:1_1",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 7.7,                                                
        CutoffMax: 772.0,                                              
        Unit: "ng/ml",                                                
        NameInReport: "Fosfatydyloetanol",                                          
        NameInAPI: "phosphatidylethanol",                                             
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
        Max: 20.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20.0,
        MaterialType: 9
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 150,
        Gender: 1,
        Min: 0.0,
        Max: 20.0,
        AnalyteId: analyte.Id,
        AgeFromMonth: 0,
        AgeToMonth: 0,
        AgeFromInMonths: 0,
        AgeToInMonths: 1800,
        Multiplier: 0.1e1,
        AcceptableMin: 0.0,
        AcceptableMax: 20.0,
        MaterialType: 9
      )
    end
  end
end
