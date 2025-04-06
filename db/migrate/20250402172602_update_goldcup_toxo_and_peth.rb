class UpdateGoldcupToxoAndPeth < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.transaction do
      Analyte.find_by(NameInAPI: "dihydrochloromethcathinone").update!(Name: "diH-CMC_1")
      Analyte.find_by(NameInAPI: "delta9-tetrahydrocannabinol (delta-9thc)").update!(Name: "THC M_Sum", NameInAPI: "delta-9thc")
      Analyte.find_by(NameInAPI: "cannabidiol (cbd)").update!(Name: "CBD M_Sum", NameInAPI: "cannabidiol")
      Analyte.find_by(NameInAPI: "11-nor-9-carboxy-delta9-tetrahydrocannabinol").update!(Name: "THCCOOH M_Sum")
      Analyte.find_by(NameInAPI: "phosphatidylethanol").update!(Name: "PEth 16:0-18:1_1", CutoffMin: 10.0, CutoffMax: 300.0)
      Analyte.find_by(NameInAPI: "fentanyl").update!(CutoffMin: 0.4)
      Analyte.find_by(NameInAPI: "fentanyl").analyte_ranges.update_all(Max: 0.4, AcceptableMax: 0.4)
      Analyte.find_by(NameInAPI: "oxycodone").update!(CutoffMin: 5.0)
      Analyte.find_by(NameInAPI: "oxycodone").analyte_ranges.update_all(Max: 5.0, AcceptableMax: 5.0)
      Analyte.find_by(NameInAPI: "oxymorphone").update!(CutoffMin: 5.0)
      Analyte.find_by(NameInAPI: "oxymorphone").analyte_ranges.update_all(Max: 5.0, AcceptableMax: 5.0)
      Analyte.find_by(NameInAPI: "noroxycodone").update!(CutoffMin: 5.0)
      Analyte.find_by(NameInAPI: "noroxycodone").analyte_ranges.update_all(Max: 5.0, AcceptableMax: 5.0)

      project = Project.find_by(Name: "Goldcup TOX")

      analyte = Analyte.create!(
        Name: "THC-OH M_Sum",                                                  
        ProjectId: project.Id,                                                 
        IsCalculatedFromOthers: false,                                 
        CutoffMin: 1,                                                
        CutoffMax: 80,                                              
        Unit: "ng/ml",                                                
        NameInReport: "11-hydroksy-delta9-tetrahydrokannabinol",                                          
        NameInAPI: "11-nor-9-hydoxy-delta9-tetrahydrocannabinol",                                             
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
    end
  end
end
