class UpdateIodineProjectForAutomaticUnitConversion < ActiveRecord::Migration[7.0]
  def change
    iodine = Analyte.find(361)
    iodine.update(IsCalculatedFromOthers: true)

    iodine_ng_per_ml = iodine.dup
    iodine_ng_per_ml.Name = "I 127 (Jod) Quant Average ng/mL"
    iodine_ng_per_ml.IsCalculatedFromOthers = false
    iodine_ng_per_ml.Unit = "ng/ml"
    iodine_ng_per_ml.CutoffMin = 12.4432
    iodine_ng_per_ml.CutoffMax = 6900.32
    iodine_ng_per_ml.NameInAPI = "iodine_ng_ml"
    iodine_ng_per_ml.save
  end
end
