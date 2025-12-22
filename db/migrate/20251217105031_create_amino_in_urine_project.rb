class CreateAminoInUrineProject < ActiveRecord::Migration[7.0]
  def change

    project = Project.create!(                                                                                                                  
            Name: "Profil aminokwasów w moczu",                                                                                                 
            Description: "Profil aminokwasów w moczu",                                                                                          
            WithCutter: true,                                                                                                                   
            PlateDimensionX: 8,                                                                                                                 
            PlateDimensionY: 12,                                                                                                                
            Prefix: nil,                                                                                                                        
            created_at: Time.now,                                                                                                               
            updated_at: Time.now,                                                                                                               
            is_blocked_online: false,                                                                                                           
            survey_description: ".",                                                                                                            
            PdfNameOfAnalysis: "Profil aminokwasów w moczu",                        
            PdfDescription: "Badanie określające stężenie ............ wykonane metodą .........",
            product_name_in_invoice: "Badanie określające stężenie ................. wykonane metodą .................. zgodnie z umową",
            pkwiu_in_invoice: "86.90.15",
            brutto_price: 0.5e2,
            FinalProtocoleHeader: nil,
            responsible_person_email: "anna.krol@masdiag.pl",
            has_selectable_analytes: false,
            InjectionVolume: 0.22e2,
            eng_name: "Amino acid profile in urine",
            is_active: true
          )

    analyte = Analyte.create!(
      Name: "Gly 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Glicyna",                                          
      NameInAPI: "glycine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Ala 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Alanina",                                          
      NameInAPI: "alanine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Ser 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Seryna",                                          
      NameInAPI: "serine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Pro 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Prolina",                                          
      NameInAPI: "proline",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Val 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Walina",                                          
      NameInAPI: "valine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Thr 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Treonina",                                          
      NameInAPI: "threonine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Ile-Leu 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Izoleucyna",                                          
      NameInAPI: "isoleucine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Asn 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Asparagina",                                          
      NameInAPI: "asparagine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Lys 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Lizyna",                                          
      NameInAPI: "lysine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Gln 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Glutamina",                                          
      NameInAPI: "glutamine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Met 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Metionina",                                          
      NameInAPI: "methionine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "His 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Histydyna",                                          
      NameInAPI: "histidine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Phe 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Fenyloalanina",                                          
      NameInAPI: "phenylalanine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Arg 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0.0625,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Arginina",                                          
      NameInAPI: "arginine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Tyr 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Tyrozyna",                                          
      NameInAPI: "tyrosine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Asp 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Kwas asparaginowy",                                          
      NameInAPI: "asparticacid",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Glu 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Kwas glutaminowy",                                          
      NameInAPI: "glutamicacid",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Trp 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Tryptofan",                                          
      NameInAPI: "tryptophan",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Sar 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0.125,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Sarkozyna",                                          
      NameInAPI: "sarcosine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Ala-bAla 2",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "beta Alanina",                                          
      NameInAPI: "beta alanine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Orn 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Ornityna",                                          
      NameInAPI: "ornithine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Cit 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Cytrulina",                                          
      NameInAPI: "citrulline",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "GABA 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0.025,                                                
      CutoffMax: 5,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Kwas gama-animomasłowy",                                          
      NameInAPI: "gammaaminobutyricacid",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Leu 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Leucyna",                                          
      NameInAPI: "leucine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Tau",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 1.25,                                                
      CutoffMax: 1625,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Tauryna",                                          
      NameInAPI: "taurine",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "hCit 1",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0.025,                                                
      CutoffMax: 125,                                              
      Unit: "nmol/ml",                                                
      NameInReport: "Homocytrulina",                                          
      NameInAPI: "homocitrulline",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: false,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    analyte = Analyte.create!(
      Name: "Gly 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Glicyna",                                          
      NameInAPI: "glycine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 9872,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 9872
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 9872,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 9872
    )

    analyte = Analyte.create!(
      Name: "Ala 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Alanina",                                          
      NameInAPI: "alanine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 2360,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 2360,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 2360
    )

    analyte = Analyte.create!(
      Name: "Ser 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Seryna",                                          
      NameInAPI: "serine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 2741,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 2741,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 2741
    )

    analyte = Analyte.create!(
      Name: "Pro 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Prolina",                                          
      NameInAPI: "proline-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 1028,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 1028,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 1028
    )

    analyte = Analyte.create!(
      Name: "Val 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Walina",                                          
      NameInAPI: "valine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 258,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 258,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 258
    )

    analyte = Analyte.create!(
      Name: "Thr 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Treonina",                                          
      NameInAPI: "threonine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 1769,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 1769,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 1769
    )

    analyte = Analyte.create!(
      Name: "Ile-Leu 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Izoleucyna",                                          
      NameInAPI: "isoleucine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 131,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 131,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 131
    )

    analyte = Analyte.create!(
      Name: "Asn 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Asparagina",                                          
      NameInAPI: "asparagine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 1159,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 1159,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 1159
    )

    analyte = Analyte.create!(
      Name: "Lys 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Lizyna",                                          
      NameInAPI: "lysine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 1321,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 1321,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 1321
    )

    analyte = Analyte.create!(
      Name: "Gln 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Glutamina",                                          
      NameInAPI: "glutamine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 3681,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 3681,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 3681
    )

    analyte = Analyte.create!(
      Name: "Met 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Metionina",                                          
      NameInAPI: "methionine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 45,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 45,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 45
    )

    analyte = Analyte.create!(
      Name: "His 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Histydyna",                                          
      NameInAPI: "histidine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 4578,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 4578,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 4578
    )

    analyte = Analyte.create!(
      Name: "Phe 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Fenyloalanina",                                          
      NameInAPI: "phenylalanine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 306,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 306,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 306
    )

    analyte = Analyte.create!(
      Name: "Arg 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Arginina",                                          
      NameInAPI: "arginine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 147,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 147,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 147
    )

    analyte = Analyte.create!(
      Name: "Tyr 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Tyrozyna",                                          
      NameInAPI: "tyrosine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 603,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 603,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 603
    )

    analyte = Analyte.create!(
      Name: "Asp 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Kwas asparaginowy",                                          
      NameInAPI: "asparticacid-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 72,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 72,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 72
    )

    analyte = Analyte.create!(
      Name: "Glu 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Kwas glutaminowy",                                          
      NameInAPI: "glutamicacid-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 210,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 210,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 210
    )

    analyte = Analyte.create!(
      Name: "Trp 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Tryptofan",                                          
      NameInAPI: "tryptophan-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 329,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 329,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 329
    )

    analyte = Analyte.create!(
      Name: "Sar 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Sarkozyna",                                          
      NameInAPI: "sarcosine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 52,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 52,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 52
    )

    analyte = Analyte.create!(
      Name: "Ala-bAla 2 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "beta Alanina",                                          
      NameInAPI: "beta alanine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 79,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 79,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 79
    )

    analyte = Analyte.create!(
      Name: "Orn 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Ornityna",                                          
      NameInAPI: "ornithine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 238,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 238,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 238
    )

    analyte = Analyte.create!(
      Name: "Cit 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Cytrulina",                                          
      NameInAPI: "citrulline-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 67,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 67,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 67
    )

    analyte = Analyte.create!(
      Name: "GABA 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Kwas gama-animomasłowy",                                          
      NameInAPI: "gammaaminobutyricacid-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 14,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 14,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 14
    )

    analyte = Analyte.create!(
      Name: "Leu 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Leucyna",                                          
      NameInAPI: "leucine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 215,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 215,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 215
    )

    analyte = Analyte.create!(
      Name: "Tau CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Tauryna",                                          
      NameInAPI: "taurine-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 5604,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 5604,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 5604
    )

    analyte = Analyte.create!(
      Name: "hCit 1 CREA",                                                  
      ProjectId: project.Id,                                                 
      IsCalculatedFromOthers: false,                                 
      CutoffMin: 0,                                                
      CutoffMax: 1000000,                                              
      Unit: "mmol/mol crea",                                                
      NameInReport: "Homocytrulina",                                          
      NameInAPI: "homocitrulline-crea",                                             
      analysis_method_name_in_batch: nil,                            
      AnalysisMethodPolarity: nil,                                   
      is_required: true,                                             
      NameInStandLab: nil,
      ExcludedFromStatistic: true,
      material_type: 5
    )

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 0,
      Min: 0,
      Max: 169,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 0,
      AgeTo: 3,
      Gender: 1,
      Min: 0,
      Max: 169,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 0,
      AgeToInMonths: 36,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 169
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Gly 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 3927,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 3927
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 3927,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 3927
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Ala 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 890,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 890,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 890
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Ser 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 850,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 850,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 850
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Pro 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 433,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 433,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 433
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Val 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 86,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 86,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 86
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Thr 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 426,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 426,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 426
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Ile-Leu 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 32,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 32,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 32
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Asn 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 326,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 326,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 326
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Lys 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 295,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 295,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 295
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Gln 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 1163,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 1163,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 1163
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Met 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 49,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 49,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 49
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "His 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 1614,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 1614,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 1614
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Phe 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 113,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 113,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 113
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Arg 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 67,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 67,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 67
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Tyr 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 365,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 365,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 365
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Asp 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 128,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 128,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 128
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Glu 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 352,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 352,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 352
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Trp 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 122,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 122,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 122
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Sar 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 51,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 51,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 51
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Ala-bAla 2 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 206,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 206,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 206
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Orn 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 91,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 91,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 91
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Cit 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 37,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 37,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 37
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "GABA 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 8,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 8,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 8
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Leu 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 73,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 73,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 73
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "Tau CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 4481,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 4481,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 4481
    )

    analyte = Analyte.where(ProjectId: project.Id).find_by(Name: "hCit 1 CREA")

    men_analyte_range = AnalyteRange.create!(
      Name: "Mężczyzna",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 0,
      Min: 0,
      Max: 36,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 0
    )

    women_analyte_range = AnalyteRange.create!(
      Name: "Kobieta",
      AgeFrom: 3,
      AgeTo: 150,
      Gender: 1,
      Min: 0,
      Max: 36,
      AnalyteId: analyte.Id,
      AgeFromInMonths: 36,
      AgeToInMonths: 1800,
      Multiplier: 0.1e1,
      AcceptableMin: 0,
      AcceptableMax: 36
    )

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
      material_type: 5
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

    Analyte.where(ProjectId: project.Id).where("Name LIKE ?", "%CREA").update_all(IsCalculatedFromOthers: true)

    AnalyteRange.includes(:analyte).where(Analytes: { ProjectId: project.Id }).where("Analytes.Name LIKE ?", "%CREA").each do |a|
      v = (a.Max * 0.11312)
      a.update(Max: v.round(0), AcceptableMax: v.round(0))
    end

  end
end
