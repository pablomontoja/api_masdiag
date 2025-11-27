class AddTotalCarnitine < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.transaction do
      project = Project.find(18)

      # total_carnitine
      analyte = Analyte.create!(
        Name: "total_carnitine",
        ProjectId: project.Id,
        IsCalculatedFromOthers: true,
        CutoffMin: 0,
        CutoffMax: 100000,
        Unit: "µmol/L",
        NameInReport: "Karnityna całkowita",
        NameInAPI: "total_carnitine",
        analysis_method_name_in_batch: nil,
        AnalysisMethodPolarity: nil,
        is_required: true,
        NameInStandLab: nil,
        ExcludedFromStatistic: true,
        material_type: :dbs
      )

      # dzieci
      men_analyte_range = AnalyteRange.create!(
        Name: "Mężczyzna",
        AgeFrom: 0,
        AgeTo: 18,
        Gender: 0,
        Min: 31.0,
        Max: 99.7,
        AnalyteId: analyte.Id,
        AgeFromInMonths: 0,
        AgeToInMonths: 216,
        Multiplier: 1,
        AcceptableMin: 31.0,
        AcceptableMax: 99.7
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 0,
        AgeTo: 18,
        Gender: 1,
        Min: 31.0,
        Max: 99.7,
        AnalyteId: analyte.Id,
        AgeFromInMonths: 0,
        AgeToInMonths: 216,
        Multiplier: 1,
        AcceptableMin: 31.0,
        AcceptableMax: 99.7
      )

      # dorośli
      men_analyte_range = AnalyteRange.create!(
        Name: "Mężczyzna",
        AgeFrom: 18,
        AgeTo: 150,
        Gender: 0,
        Min: 33.4,
        Max: 79.8,
        AnalyteId: analyte.Id,
        AgeFromInMonths: 216,
        AgeToInMonths: 1800,
        Multiplier: 1,
        AcceptableMin: 33.4,
        AcceptableMax: 79.8
      )

      women_analyte_range = AnalyteRange.create!(
        Name: "Kobieta",
        AgeFrom: 18,
        AgeTo: 150,
        Gender: 1,
        Min: 33.4,
        Max: 79.8,
        AnalyteId: analyte.Id,
        AgeFromInMonths: 216,
        AgeToInMonths: 1800,
        Multiplier: 1,
        AcceptableMin: 33.4,
        AcceptableMax: 79.8
      )
    end

  end
end
