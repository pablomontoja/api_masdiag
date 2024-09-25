module MaterialHandlers
	HASH = { dbs_t4: "Bibuła standardowa TFN4",	dbs_t5: "Bibuła TFN5",	dbs_b4: "Bibuła BHT4",	dbs_b5: "Bibuła BHT5", dbs_f4: "Bibuła FAPS4", urine_vial: "Fiolka na mocz", blood_vial: "Fiolka na krew", dbs_n2: "Bibuła NEM2", dbs_n4: "Bibuła NEM4", dbs_i4: "Bibuła IAA4" }.freeze
	MODEL_HASH = { dbs_t4: 0, dbs_t5: 1, dbs_b4: 2, dbs_b5: 3, dbs_f4: 4, urine_vial: 5, blood_vial: 6, dbs_n2: 7, dbs_n4: 8, dbs_i4: 9 }
	OPTIONS_FOR_SELECT = HASH.map{|m| [m[1],m[0]]}.freeze
	MATERIAL_TYPE = { dbs_t4: :dbs, dbs_t5: :dbs, dbs_b4: :dbs, dbs_b5: :dbs, dbs_f4: :dbs, dbs_n2: :dbs, dbs_n4: :dbs, dbs_i4: :dbs, urine_vial: :urine, blood_vial: :blood_serum }
	MATERIAL_TYPE_BASED_ON_MODIFICATOR = { dbs_faps: :dbs, dbs_nem: :dbs, dbs_bht: :dbs, dbs_tfn: :dbs, dbs_iaa: :dbs, blood_vial: :blood_serum, urine_vial: :urine }
end