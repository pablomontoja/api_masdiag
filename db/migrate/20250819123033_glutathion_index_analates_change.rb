class GlutathionIndexAnalatesChange < ActiveRecord::Migration[7.0]
  def change
    glu_index = Analyte.find(325)
    glu_index.update(IsCalculatedFromOthers: true)

    gsh = Analyte.find(326)
    gsh.update(IsCalculatedFromOthers: true)

    gssg = Analyte.find(327)
    gssg.update(IsCalculatedFromOthers: true)

    # GSH µg/ml
    analyte = Analyte.create!(
      Name: "GSH-IAM 4",
      ProjectId: 26,
      IsCalculatedFromOthers: false,
      CutoffMin: nil,
      CutoffMax: nil,
      Unit: "µg/ml",
      NameInReport: "GSH µg/ml",
      NameInAPI: "gsh-ng-per-ml",
      analysis_method_name_in_batch: nil,
      AnalysisMethodPolarity: nil,
      is_required: false,
      NameInStandLab: nil,
      ExcludedFromStatistic: true
    )

    # GSSG µg/ml
    analyte = Analyte.create!(
      Name: "GSSG 2 multi",
      ProjectId: 26,
      IsCalculatedFromOthers: false,
      CutoffMin: nil,
      CutoffMax: nil,
      Unit: "µg/ml",
      NameInReport: "GSSG µg/ml",
      NameInAPI: "gssg-ng-per-ml",
      analysis_method_name_in_batch: nil,
      AnalysisMethodPolarity: nil,
      is_required: false,
      NameInStandLab: nil,
      ExcludedFromStatistic: true
    )
  end
end
