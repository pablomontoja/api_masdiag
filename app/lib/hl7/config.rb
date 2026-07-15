module Hl7
  module Config
    ARCHIVE_FOLDER = "archive"

    # ⚠️ BLOCKER: must be set before first import — integer ID of system user for Result.ImportUserId
    # Find with: User.find(24) or check Cerascreen::Labordatenbank::ResultImporterJob
    SYSTEM_USER_ID = 24

    # Instrument ID assigned to Measurements after successful HL7 import
    # Find with: Instrument.find_by(name: "NutriPATH") or check instruments table
    INSTRUMENT_ID = 15

    # Molar mass of creatinine in g/mol — used for unit conversions
    # mmol/L → mg/dl:  value_mg_dl  = mmol_per_L × CREATININE_MOLAR_MASS / 10
    # mmol/L → g/L:    value_g_per_L = mmol_per_L × CREATININE_MOLAR_MASS / 1000
    CREATININE_MOLAR_MASS = 113.12

    # Maps HL7 OBR-4 first component (before first ^) → ProjectId
    TEST_MAPPING = {
      "UCR,usEssEl,UsMetox"            => 32,  # NutriPATH urine metals panel
      "UR-IODINE,uIodEx,UIodCom,usCr"  => 29   # NutriPATH urine iodine panel
    }.freeze

    # Maps HL7 OBX-3 first component → Analyte.NameInAPI
    #
    # Key conventions:
    #   - Plain key (e.g. "42220-4")          → raw/absolute analyte; value converted from ug/gCR to µg/L
    #   - "_crea" suffix (e.g. "42220-4_crea") → creatinine-normalized variant; value stored directly
    #   - Identifiers in UG_PER_L_DIRECT_IDENTIFIERS → already in ug/L, stored as ng/ml (1:1)
    ANALYTE_MAPPING = {
      # ── Project 32: NutriPATH Urine Metals ──────────────────────────────────

      # Creatinine (Project 32) — mmol/L → mg/dl: × 113.12 / 10
      "UCR"     => "krea",
      "CrSpUr"  => "krea",

      # Raw absolute (µg/L in DB) — converted from ug/gCR via creatinine back-calculation
      "42220-4" => "chromium",
      "34270-9" => "cobalt",
      "13829-7" => "copper",
      "13465-0" => "mercury",
      "13466-8" => "lead",
      "13470-0" => "aluminium",
      "13463-5" => "arsenic",
      "56651-3" => "cadmium",
      "13472-6" => "nickel",
      "13473-4" => "zinc",          # HL7 unit: mg/gCR → factor ×1000 applied

      # Creatinine-normalized (µg/g crea in DB) — stored directly from HL7
      "42220-4_crea" => "chromium_crea",
      "34270-9_crea" => "cobalt_crea",
      "13829-7_crea" => "copper_crea",
      "13465-0_crea" => "mercury_crea",
      "13466-8_crea" => "lead_crea",
      "13470-0_crea" => "aluminium_crea",
      "13463-5_crea" => "arsenic_crea",
      "56651-3_crea" => "cadmium_crea",
      "13472-6_crea" => "nickel_crea",
      "13473-4_crea" => "zinc_crea",

      # ── Project 29: NutriPATH Urine Iodine ──────────────────────────────────

      # Creatinine (Project 29) — mmol/L → mg/dl: × 113.12 / 10
      "usCr"      => "kreatinin_iu",

      # Iodine creatinine-normalized (ug/g creatinine in DB) — stored directly
      "uIodEx"    => "jod_krea_iu",

      # Iodine absolute (ng/ml in DB) — HL7 is ug/L; 1 ug/L = 1 ng/ml (1:1)
      "UR-IODINE" => "iodine_ng_ml"
    }.freeze

    # OBX-3 identifiers whose HL7 value is already in ug/L and maps to ng/ml DB units (1:1, no arithmetic)
    UG_PER_L_DIRECT_IDENTIFIERS = %w[UR-IODINE].freeze

    # OBX-3 identifiers whose HL7 value is stored directly as-is in the DB (no unit conversion)
    # e.g. uIodEx arrives as ug/gCR and is stored directly as ug/g creatinine
    DIRECT_STORE_IDENTIFIERS = %w[uIodEx].freeze
  end
end
