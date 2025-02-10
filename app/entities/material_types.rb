# Please remember to update storage and labpanel project, after updating below module
module MaterialTypes
	HASH = { dbs: "Krew na bibule",	blood_serum: "Surowica krwi",	blood_plasma: "Osocze krwi",	hairs: "Włosy",	nails: "Paznokcie",	urine: "Mocz", saliva: "Ślina", aqueous_humor: "Płyn z gałki ocznej", whole_blood: "Krew pełna", capitainer: "Capitainer"	}.freeze
	MODEL_HASH = { dbs: 0, blood_serum: 1, blood_plasma: 2, hairs: 3, nails: 4, urine: 5, saliva: 6, aqueous_humor: 7, whole_blood: 8, capitainer: 9 }
	OPTIONS_FOR_SELECT = HASH.map{|m| [m[1],m[0]]}.freeze
end