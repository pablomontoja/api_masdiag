module MaterialHandlers
	HASH = { dbs_t4: "Bibuła standardowa TFN4",	dbs_t5: "Bibuła TFN5",	dbs_b4: "Bibuła BHT4",	dbs_b5: "Bibuła BHT5", dbs_f4: "Bibuła FAPS4", urine_vial: "Fiolka na mocz", blood_vial: "Fiolka na krew" }.freeze
	MODEL_HASH = { dbs_t4: 0, dbs_t5: 1, dbs_b4: 2, dbs_b5: 3, dbs_f4: 4, urine_vial: 5, blood_vial: 6 }
	OPTIONS_FOR_SELECT = HASH.map{|m| [m[1],m[0]]}.freeze
	MATERIAL_TYPE = { dbs_t4: :dbs, dbs_t5: :dbs, dbs_b4: :dbs, dbs_b5: :dbs, dbs_f4: :dbs, urine_vial: :urine, blood_vial: :blood_serum }
end