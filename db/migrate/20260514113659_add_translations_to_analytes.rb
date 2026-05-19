class AddTranslationsToAnalytes < ActiveRecord::Migration[7.0]
  def change
    inactive_project_ids = [1, 5, 6, 7, 8, 9, 11, 13, 14, 16, 17, 19]
    Project.where(Id: inactive_project_ids).update_all(is_active: false)
    Project.where.not(Id: inactive_project_ids).update_all(is_active: true)

    I18n.locale = :en

    # Vit D
    Analyte.find(84).update(NameInReport: "Total 25(OH)D concentration")

    # Amino
    amino_names = [{"Name"=>"Ala 1", "NameInReport"=>"Alanine"},
      {"Name"=>"Arg 1", "NameInReport"=>"Arginine"},
      {"Name"=>"Asn 1", "NameInReport"=>"Asparagine"},
      {"Name"=>"Asp 1", "NameInReport"=>"Aspartic acid"},
      {"Name"=>"Gln 1", "NameInReport"=>"Glutamine"},
      {"Name"=>"Glu 1", "NameInReport"=>"Glutamic acid"},
      {"Name"=>"Gly 1", "NameInReport"=>"Glycine"},
      {"Name"=>"His 1", "NameInReport"=>"Histidine"},
      {"Name"=>"Ile 1", "NameInReport"=>"Isoleucine"},
      {"Name"=>"Leu 1", "NameInReport"=>"Leucine"},
      {"Name"=>"Lys 1", "NameInReport"=>"Lysine"},
      {"Name"=>"Met 1", "NameInReport"=>"Methionine"},
      {"Name"=>"Phe 1", "NameInReport"=>"Phenylalanine"},
      {"Name"=>"Pro 1", "NameInReport"=>"Proline"},
      {"Name"=>"Ser 1", "NameInReport"=>"Serine"},
      {"Name"=>"Thr 1", "NameInReport"=>"Threonine"},
      {"Name"=>"Trp 1", "NameInReport"=>"Tryptophan"},
      {"Name"=>"Tyr 1", "NameInReport"=>"Tyrosine"},
      {"Name"=>"Val 1", "NameInReport"=>"Valine"},
      {"Name"=>"bAla 1", "NameInReport"=>"Beta-alanine"},
      {"Name"=>"Cit 1", "NameInReport"=>"Citrulline"},
      {"Name"=>"hArg 7", "NameInReport"=>"Homoarginine"},
      {"Name"=>"Orn 1", "NameInReport"=>"Ornithine"},
      {"Name"=>"Sarc 1", "NameInReport"=>"Sarcosine"},
      {"Name"=>"Tau", "NameInReport"=>"Taurine"},
      {"Name"=>"GABA 1", "NameInReport"=>"Gamma-aminobutyric acid"}]

    MaterialTypes::MODEL_HASH.keys.each do |m|
      Analyte.where(ProjectId: 3, material_type: m).each do |analyte|
        an = amino_names.select{ |a| a["Name"] == analyte.Name }.first
        analyte.update(NameInReport: an["NameInReport"])
      end
    end

    # Acylocarnitines
    Analyte.find_by(ProjectId: 18, Name: "total_carnitine").update(NameInReport: "Total carnitine")

    # Arginine
    arg_names = [{"Name"=>"ARG 1", "NameInReport"=>"Arginine"},
     {"Name"=>"ORN 1", "NameInReport"=>"Ornithine"},
     {"Name"=>"Arg/Orn", "NameInReport"=>"Arginine/Ornithine"}]

    Analyte.where(ProjectId: 30, material_type: :dbs).each do |analyte|
      an = arg_names.select{ |a| a["Name"] == analyte.Name }.first
      analyte.update(NameInReport: an["NameInReport"])
    end

    # Glutathione Index 
    Analyte.find_by(ProjectId: 26, Name: "Index").update(NameInReport: "Glutathione Index (GSH/GSSG)")

    # Glycated hemoglobin (HbA1c)
    Analyte.find_by(ProjectId: 23, Name: "HbA1c").update(NameInReport: "Glycated hemoglobin (HbA1c)")

    # Homocysteine
    MaterialTypes::MODEL_HASH.keys.each do |m|
      Analyte.find_by(ProjectId: 12, Name: "HCY_BuOH", material_type: m)&.update(NameInReport: "Homocysteine")
    end

    # Metanephrines
    meta_names = [{"Name"=>"metanefryna_1", "NameInReport"=>"Metanephrine (MT)", "material_type"=>"blood_plasma"},
     {"Name"=>"normetanefryna_1", "NameInReport"=>"Normetanephrine (NMT)", "material_type"=>"blood_plasma"},
     {"Name"=>"3-metoxy_2 multi", "NameInReport"=>"3-Methoxytyramine (3-MT)", "material_type"=>"blood_plasma"}]

    Analyte.where(ProjectId: 20, material_type: :blood_plasma).each do |analyte|
      an = meta_names.select{ |a| a["Name"] == analyte.Name }.first
      analyte.update(NameInReport: an["NameInReport"])
    end

    # DAO
    Analyte.find_by(ProjectId: 24, Name: "DAO").update(NameInReport: "Diamine oxidase (DAO)")

    # 3-O-metylo-DOPA (3-OMD)
    Analyte.find_by(ProjectId: 25, Name: "3OMD 1").update(NameInReport: "3-O-Methyldopa (3-OMD)")

    # Omega Complete
    omega_names = [{"Name"=>"Kwasy tłuszczowe omega-3", "NameInReport"=>"Omega-3 fatty acids", "material_type"=>"dbs"},
      {"Name"=>"ADJ O3I", "NameInReport"=>"Omega-3 Index", "material_type"=>"dbs"},
      {"Name"=>"C18:3n3", "NameInReport"=>"alpha-linolenic acid (ALA, 18:3n3)", "material_type"=>"dbs"},
      {"Name"=>"C20:5n3", "NameInReport"=>"eicosapentaenoic acid (EPA, 20:5n3)", "material_type"=>"dbs"},
      {"Name"=>"C22:5n3", "NameInReport"=>"docosapentaenoic acid-n3 (22:5n3)", "material_type"=>"dbs"},
      {"Name"=>"C22:6n3", "NameInReport"=>"docosahexaenoic acid (DHA, 22:6n3)", "material_type"=>"dbs"},
      {"Name"=>"Kwasy tłuszczowe omega-6", "NameInReport"=>"Omega-6 fatty acids", "material_type"=>"dbs"},
      {"Name"=>"C18:2n6", "NameInReport"=>"linoleic acid (18:2n6)", "material_type"=>"dbs"},
      {"Name"=>"C18:3n6", "NameInReport"=>"gamma-linolenic acid (18:3n6)", "material_type"=>"dbs"},
      {"Name"=>"C20:2n6", "NameInReport"=>"eicosadienoic acid (20:2n6)", "material_type"=>"dbs"},
      {"Name"=>"C20:3n6", "NameInReport"=>"dihomo-gamma-linolenic acid (20:3n6)", "material_type"=>"dbs"},
      {"Name"=>"C20:4n6", "NameInReport"=>"arachidonic acid (AA, 20:4n6)", "material_type"=>"dbs"},
      {"Name"=>"C22:4n6", "NameInReport"=>"docosatetraenoic acid (22:4n6)", "material_type"=>"dbs"},
      {"Name"=>"C22:5n6", "NameInReport"=>"docosapentaenoic acid-n6 (22:5n6)", "material_type"=>"dbs"},
      {"Name"=>"cis-mononienasycone kwasy tłuszczowe", "NameInReport"=>"cis-monounsaturated fatty acids", "material_type"=>"dbs"},
      {"Name"=>"C16:1n7", "NameInReport"=>"palmitoleic acid (16:1n7)", "material_type"=>"dbs"},
      {"Name"=>"C18:1n9", "NameInReport"=>"oleic acid (18:1n9)", "material_type"=>"dbs"},
      {"Name"=>"C20:1n9", "NameInReport"=>"eicosenoic acid (20:1n9)", "material_type"=>"dbs"},
      {"Name"=>"C24:1n9", "NameInReport"=>"nervonic acid (24:1n9)", "material_type"=>"dbs"},
      {"Name"=>"Nasycone kwasy tłuszczowe", "NameInReport"=>"Saturated fatty acids", "material_type"=>"dbs"},
      {"Name"=>"C14:0", "NameInReport"=>"myristic acid (14:0)", "material_type"=>"dbs"},
      {"Name"=>"C16:0", "NameInReport"=>"palmitic acid (16:0)", "material_type"=>"dbs"},
      {"Name"=>"C18:0", "NameInReport"=>"stearic acid (18:0)", "material_type"=>"dbs"},
      {"Name"=>"C20:0", "NameInReport"=>"arachidic acid (20:0)", "material_type"=>"dbs"},
      {"Name"=>"C22:0", "NameInReport"=>"behenic acid (22:0)", "material_type"=>"dbs"},
      {"Name"=>"C24:0", "NameInReport"=>"lignoceric acid (24:0)", "material_type"=>"dbs"},
      {"Name"=>"Izomery trans kwasów tłuszczowych", "NameInReport"=>"Trans fatty acid isomers", "material_type"=>"dbs"},
      {"Name"=>"C16:1n7t", "NameInReport"=>"trans-palmitoleic acid (16:1n7t)", "material_type"=>"dbs"},
      {"Name"=>"C18:1t", "NameInReport"=>"trans-oleic acid (18:1t)", "material_type"=>"dbs"},
      {"Name"=>"C18:2n6t", "NameInReport"=>"trans-linoleic acid (18:2n6t)", "material_type"=>"dbs"},
      {"Name"=>"TFI", "NameInReport"=>"Trans Fat Index", "material_type"=>"dbs"},
      {"Name"=>"AA:EPA", "NameInReport"=>"AA:EPA", "material_type"=>"dbs"},
      {"Name"=>"Omega-6:Omega-3", "NameInReport"=>"Omega-6:Omega-3", "material_type"=>"dbs"},
      {"Name"=>"PalmitateIndex", "NameInReport"=>"PalmitateIndex", "material_type"=>"dbs"},
      {"Name"=>"Omega3Score", "NameInReport"=>"Omega3Score", "material_type"=>"dbs"},
      {"Name"=>"Prenatal DHA", "NameInReport"=>"Prenatal DHA", "material_type"=>"dbs"}]

    MaterialTypes::MODEL_HASH.keys.each do |m|
      Analyte.where(ProjectId: 21, material_type: m).each do |analyte|
        an = omega_names.select{ |a| a["Name"] == analyte.Name }.first
        analyte.update(NameInReport: an["NameInReport"])
      end
    end

    # Omega Basic
    Analyte.find_by(ProjectId: 34, Name: "ADJ O3I", material_type: :dbs).update(NameInReport: "Omega-3 Index")
    Analyte.find_by(ProjectId: 34, Name: "ADJ O3I", material_type: :whole_blood).update(NameInReport: "Omega-3 Index")

    # WitAEQ10
    witaeq_names = [{"Name"=>"A", "NameInReport"=>"Vitamin A", "material_type"=>"dbs"},
     {"Name"=>"E", "NameInReport"=>"Vitamin E", "material_type"=>"dbs"},
     {"Name"=>"Q10", "NameInReport"=>"Coenzyme Q10", "material_type"=>"dbs"}]

    MaterialTypes::MODEL_HASH.keys.each do |m|
      Analyte.where(ProjectId: 10, material_type: m).each do |analyte|
        an = witaeq_names.select{ |a| a["Name"] == analyte.Name }.first
        analyte.update(NameInReport: an["NameInReport"])
      end
    end

    # Wit D Basic
    Analyte.find(316).update(NameInReport: "Total 25(OH)D concentration")

    # Amino in urine
    aaurine_names = [{"Id"=>709, "Name"=>"Gly 1", "NameInReport"=>"Glycine", "material_type"=>"urine"},
      {"Id"=>710, "Name"=>"Ala 1", "NameInReport"=>"Alanine", "material_type"=>"urine"},
      {"Id"=>711, "Name"=>"Ser 1", "NameInReport"=>"Serine", "material_type"=>"urine"},
      {"Id"=>712, "Name"=>"Pro 1", "NameInReport"=>"Proline", "material_type"=>"urine"},
      {"Id"=>713, "Name"=>"Val 1", "NameInReport"=>"Valine", "material_type"=>"urine"},
      {"Id"=>714, "Name"=>"Thr 1", "NameInReport"=>"Threonine", "material_type"=>"urine"},
      {"Id"=>715, "Name"=>"Ile-Leu 1", "NameInReport"=>"Isoleucine", "material_type"=>"urine"},
      {"Id"=>716, "Name"=>"Asn 1", "NameInReport"=>"Asparagine", "material_type"=>"urine"},
      {"Id"=>717, "Name"=>"Lys 1", "NameInReport"=>"Lysine", "material_type"=>"urine"},
      {"Id"=>718, "Name"=>"Gln 1", "NameInReport"=>"Glutamine", "material_type"=>"urine"},
      {"Id"=>719, "Name"=>"Met 1", "NameInReport"=>"Methionine", "material_type"=>"urine"},
      {"Id"=>720, "Name"=>"His 1", "NameInReport"=>"Histidine", "material_type"=>"urine"},
      {"Id"=>721, "Name"=>"Phe 1", "NameInReport"=>"Phenylalanine", "material_type"=>"urine"},
      {"Id"=>722, "Name"=>"Arg 1", "NameInReport"=>"Arginine", "material_type"=>"urine"},
      {"Id"=>723, "Name"=>"Tyr 1", "NameInReport"=>"Tyrosine", "material_type"=>"urine"},
      {"Id"=>724, "Name"=>"Asp 1", "NameInReport"=>"Aspartic acid", "material_type"=>"urine"},
      {"Id"=>725, "Name"=>"Glu 1", "NameInReport"=>"Glutamic acid", "material_type"=>"urine"},
      {"Id"=>726, "Name"=>"Trp 1", "NameInReport"=>"Tryptophan", "material_type"=>"urine"},
      {"Id"=>727, "Name"=>"Sar 1", "NameInReport"=>"Sarcosine", "material_type"=>"urine"},
      {"Id"=>728, "Name"=>"Ala-bAla 2", "NameInReport"=>"beta-Alanine", "material_type"=>"urine"},
      {"Id"=>729, "Name"=>"Orn 1", "NameInReport"=>"Ornithine", "material_type"=>"urine"},
      {"Id"=>730, "Name"=>"Cit 1", "NameInReport"=>"Citrulline", "material_type"=>"urine"},
      {"Id"=>731, "Name"=>"GABA 1", "NameInReport"=>"Gamma-aminobutyric acid", "material_type"=>"urine"},
      {"Id"=>732, "Name"=>"Leu 1", "NameInReport"=>"Leucine", "material_type"=>"urine"},
      {"Id"=>733, "Name"=>"Tau", "NameInReport"=>"Taurine", "material_type"=>"urine"},
      {"Id"=>734, "Name"=>"hCit 1", "NameInReport"=>"Homocitrulline", "material_type"=>"urine"},
      {"Id"=>735, "Name"=>"Gly 1 CREA", "NameInReport"=>"Glycine", "material_type"=>"urine"},
      {"Id"=>736, "Name"=>"Ala 1 CREA", "NameInReport"=>"Alanine", "material_type"=>"urine"},
      {"Id"=>737, "Name"=>"Ser 1 CREA", "NameInReport"=>"Serine", "material_type"=>"urine"},
      {"Id"=>738, "Name"=>"Pro 1 CREA", "NameInReport"=>"Proline", "material_type"=>"urine"},
      {"Id"=>739, "Name"=>"Val 1 CREA", "NameInReport"=>"Valine", "material_type"=>"urine"},
      {"Id"=>740, "Name"=>"Thr 1 CREA", "NameInReport"=>"Threonine", "material_type"=>"urine"},
      {"Id"=>741, "Name"=>"Ile-Leu 1 CREA", "NameInReport"=>"Isoleucine", "material_type"=>"urine"},
      {"Id"=>742, "Name"=>"Asn 1 CREA", "NameInReport"=>"Asparagine", "material_type"=>"urine"},
      {"Id"=>743, "Name"=>"Lys 1 CREA", "NameInReport"=>"Lysine", "material_type"=>"urine"},
      {"Id"=>744, "Name"=>"Gln 1 CREA", "NameInReport"=>"Glutamine", "material_type"=>"urine"},
      {"Id"=>745, "Name"=>"Met 1 CREA", "NameInReport"=>"Methionine", "material_type"=>"urine"},
      {"Id"=>746, "Name"=>"His 1 CREA", "NameInReport"=>"Histidine", "material_type"=>"urine"},
      {"Id"=>747, "Name"=>"Phe 1 CREA", "NameInReport"=>"Phenylalanine", "material_type"=>"urine"},
      {"Id"=>748, "Name"=>"Arg 1 CREA", "NameInReport"=>"Arginine", "material_type"=>"urine"},
      {"Id"=>749, "Name"=>"Tyr 1 CREA", "NameInReport"=>"Tyrosine", "material_type"=>"urine"},
      {"Id"=>750, "Name"=>"Asp 1 CREA", "NameInReport"=>"Aspartic acid", "material_type"=>"urine"},
      {"Id"=>751, "Name"=>"Glu 1 CREA", "NameInReport"=>"Glutamic acid", "material_type"=>"urine"},
      {"Id"=>752, "Name"=>"Trp 1 CREA", "NameInReport"=>"Tryptophan", "material_type"=>"urine"},
      {"Id"=>753, "Name"=>"Sar 1 CREA", "NameInReport"=>"Sarcosine", "material_type"=>"urine"},
      {"Id"=>754, "Name"=>"Ala-bAla 2 CREA", "NameInReport"=>"beta-Alanine", "material_type"=>"urine"},
      {"Id"=>755, "Name"=>"Orn 1 CREA", "NameInReport"=>"Ornithine", "material_type"=>"urine"},
      {"Id"=>756, "Name"=>"Cit 1 CREA", "NameInReport"=>"Citrulline", "material_type"=>"urine"},
      {"Id"=>757, "Name"=>"GABA 1 CREA", "NameInReport"=>"Gamma-aminobutyric acid", "material_type"=>"urine"},
      {"Id"=>758, "Name"=>"Leu 1 CREA", "NameInReport"=>"Leucine", "material_type"=>"urine"},
      {"Id"=>759, "Name"=>"Tau CREA", "NameInReport"=>"Taurine", "material_type"=>"urine"},
      {"Id"=>760, "Name"=>"hCit 1 CREA", "NameInReport"=>"Homocitrulline", "material_type"=>"urine"},
      {"Id"=>761, "Name"=>"Creatinine", "NameInReport"=>"Creatinine", "material_type"=>"urine"}]

    Analyte.where(ProjectId: 37, material_type: :urine).each do |analyte|
      an = aaurine_names.select{ |a| a["Name"] == analyte.Name }.first
      analyte.update(NameInReport: an["NameInReport"])
    end




    ###########################################
    # final TOXO names update
    ###########################################
    I18n.locale = :pl

    joined = [{"Id"=>1067, "Name"=>"Oksykodon (OXY) 1", "NameInReport"=>"Oksykodon (OXY) 1", "NameInAPI"=>"oxycodone_1"},
     {"Id"=>1073, "Name"=>"Oksykodon (OXY) 2", "NameInReport"=>"Oksykodon (OXY) 2", "NameInAPI"=>"oxycodone_2"},
     {"Id"=>1079, "Name"=>"Oksymorfon (OXYM) 1", "NameInReport"=>"Oksymorfon (OXYM) 1", "NameInAPI"=>"oxymorphone_1"},
     {"Id"=>1085, "Name"=>"Oksymorfon (OXYM) 2", "NameInReport"=>"Oksymorfon (OXYM) 2", "NameInAPI"=>"oxymorphone_2"},
     {"Id"=>1091, "Name"=>"Noroksykodon (norOXY) 1", "NameInReport"=>"Noroksykodon (norOXY) 1", "NameInAPI"=>"noroxycodone_1"},
     {"Id"=>1097, "Name"=>"Noroksykodon (norOXY) 2", "NameInReport"=>"Noroksykodon (norOXY) 2", "NameInAPI"=>"noroxycodone_2"},
     {"Id"=>791, "Name"=>"Morfina (MOR) 1", "NameInReport"=>"Morfina (MOR) 1", "NameInAPI"=>"morphine_1"},
     {"Id"=>797, "Name"=>"Morfina (MOR) 2", "NameInReport"=>"Morfina (MOR) 2", "NameInAPI"=>"morphine_2"},
     {"Id"=>803, "Name"=>"Kodeina (COD) 1", "NameInReport"=>"Kodeina (COD) 1", "NameInAPI"=>"codeine_1"},
     {"Id"=>809, "Name"=>"Kodeina (COD) 2", "NameInReport"=>"Kodeina (COD) 2", "NameInAPI"=>"codeine_2"},
     {"Id"=>851, "Name"=>"6-monoacetylomorfina (6-AM) 1", "NameInReport"=>"6-monoacetylomorfina (6-AM) 1", "NameInAPI"=>"6-acetylmorphine_1"},
     {"Id"=>857, "Name"=>"6-monoacetylomorfina (6-AM) 2", "NameInReport"=>"6-monoacetylomorfina (6-AM) 2", "NameInAPI"=>"6-acetylmorphine_2"},
     {"Id"=>947, "Name"=>"Fentanyl (FENT) 1", "NameInReport"=>"Fentanyl (FENT) 1", "NameInAPI"=>"fentanyl_1"},
     {"Id"=>953, "Name"=>"Fentanyl (FENT) 2", "NameInReport"=>"Fentanyl (FENT) 2", "NameInAPI"=>"fentanyl_2"},
     {"Id"=>863, "Name"=>"Tramadol (TRAM) 1", "NameInReport"=>"Tramadol (TRAM) 1", "NameInAPI"=>"tramadol_1"},
     {"Id"=>869, "Name"=>"Tramadol (TRAM) 2", "NameInReport"=>"Tramadol (TRAM) 2", "NameInAPI"=>"tramadol_2"},
     {"Id"=>1031, "Name"=>"Metadon (META) 1", "NameInReport"=>"Metadon (META) 1", "NameInAPI"=>"methadone_1"},
     {"Id"=>1037, "Name"=>"Metadon (META) 2", "NameInReport"=>"Metadon (META) 2", "NameInAPI"=>"methadone_2"},
     {"Id"=>899, "Name"=>"Klonazepam (CLO) 1", "NameInReport"=>"Klonazepam (CLO) 1", "NameInAPI"=>"clonazepam_1"},
     {"Id"=>905, "Name"=>"Klonazepam (CLO) 2", "NameInReport"=>"Klonazepam (CLO) 2", "NameInAPI"=>"clonazepam_2"},
     {"Id"=>923, "Name"=>"7-aminoklonazapam (7aCLO) 1", "NameInReport"=>"7-aminoklonazepam (7aCLO) 1", "NameInAPI"=>"7-aminoclonazepam_1"},
     {"Id"=>929, "Name"=>"7-aminoklonazapam (7aCLO) 2", "NameInReport"=>"7-aminoklonazepam (7aCLO) 2", "NameInAPI"=>"7-aminoclonazepam_2"},
     {"Id"=>935, "Name"=>"Flunitrazepam (FN) 1", "NameInReport"=>"Flunitrazepam (FN) 1", "NameInAPI"=>"flunitrazepam_1"},
     {"Id"=>941, "Name"=>"Flunitrazepam (FN) 2", "NameInReport"=>"Flunitrazepam (FN) 2", "NameInAPI"=>"flunitrazepam_2"},
     {"Id"=>959, "Name"=>"7-aminoflunitrazepam (7FN) 1", "NameInReport"=>"7-aminoflunitrazepam (7FN) 1", "NameInAPI"=>"7-aminoflunitrazepam_1"},
     {"Id"=>965, "Name"=>"7-aminoflunitrazepam (7FN) 2", "NameInReport"=>"7-aminoflunitrazepam (7FN) 2", "NameInAPI"=>"7-aminoflunitrazepam_2"},
     {"Id"=>983, "Name"=>"Lorazepam (LORA) 1", "NameInReport"=>"Lorazepam (LORA) 1", "NameInAPI"=>"lorazepam_1"},
     {"Id"=>989, "Name"=>"Lorazepam (LORA) 2", "NameInReport"=>"Lorazepam (LORA) 2", "NameInAPI"=>"lorazepam_2"},
     {"Id"=>1043, "Name"=>"Diazepam (DIAZ) 1", "NameInReport"=>"Diazepam (DIAZ) 1", "NameInAPI"=>"diazepam_1"},
     {"Id"=>1049, "Name"=>"Diazepam (DIAZ) 2", "NameInReport"=>"Diazepam (DIAZ) 2", "NameInAPI"=>"diazepam_2"},
     {"Id"=>1007, "Name"=>"Nordiazepam (norDIAZ) 1", "NameInReport"=>"Nordiazepam (norDIAZ) 1", "NameInAPI"=>"nordiazepam_1"},
     {"Id"=>1013, "Name"=>"Nordiazepam (norDIAZ) 2", "NameInReport"=>"Nordiazepam (norDIAZ) 2", "NameInAPI"=>"nordiazepam_2"},
     {"Id"=>1019, "Name"=>"Oksazepam (OXAZ) 1", "NameInReport"=>"Oksazepam (OXAZ) 1", "NameInAPI"=>"oxazepam_1"},
     {"Id"=>1025, "Name"=>"Oksazepam (OXAZ) 2", "NameInReport"=>"Oksazepam (OXAZ) 2", "NameInAPI"=>"oxazepam_2"},
     {"Id"=>1055, "Name"=>"Alprazolam (ALPR) 1", "NameInReport"=>"Alprazolam (ALPR) 1", "NameInAPI"=>"alprazolam_1"},
     {"Id"=>1061, "Name"=>"Alprazolam (ALPR) 2", "NameInReport"=>"Alprazolam (ALPR) 2", "NameInAPI"=>"alprazolam_2"},
     {"Id"=>1139, "Name"=>"Kannabidiol (CBD) 1", "NameInReport"=>"Kannabidiol (CBD) 1", "NameInAPI"=>"cannabidiol (cbd)_1"},
     {"Id"=>1145, "Name"=>"Kannabidiol (CBD) 2", "NameInReport"=>"Kannabidiol (CBD) 2", "NameInAPI"=>"cannabidiol (cbd)_2"},
     {"Id"=>1127, "Name"=>"delta-9-tetrahydrokannabinol (9-THC) 1", "NameInReport"=>"delta-9-tetrahydrokannabinol (9-THC) 1", "NameInAPI"=>"delta9-tetrahydrocannabinol (delta-9thc)_1"},
     {"Id"=>1133, "Name"=>"delta-9-tetrahydrokannabinol (9-THC) 2", "NameInReport"=>"delta-9-tetrahydrokannabinol (9-THC) 2", "NameInAPI"=>"delta9-tetrahydrocannabinol (delta-9thc)_2"},
     {"Id"=>1163, "Name"=>"11-hydroksy-delta-9-tetrahydrokannabinol (9-THC-OH) 1", "NameInReport"=>"11-hydroksy-delta-9-tetrahydrokannabinol (9-THC-OH) 1", "NameInAPI"=>"11-nor-9-hydoxy-delta9-tetrahydrocannabinol_1"},
     {"Id"=>1169, "Name"=>"11-hydroksy-delta-9-tetrahydrokannabinol (9-THC-OH) 2", "NameInReport"=>"11-hydroksy-delta-9-tetrahydrokannabinol (9-THC-OH) 2", "NameInAPI"=>"11-nor-9-hydoxy-delta9-tetrahydrocannabinol_2"},
     {"Id"=>1151, "Name"=>"11-karboksy-delta-9-tetrahydrokannabinol (9-THC-COOH) 1", "NameInReport"=>"11-karboksy-delta-9-tetrahydrokannabinol (9-THC-COOH) 1", "NameInAPI"=>"11-nor-9-carboxy-delta9-tetrahydrocannabinol_1"},
     {"Id"=>1157, "Name"=>"11-karboksy-delta-9-tetrahydrokannabinol (9-THC-COOH) 2", "NameInReport"=>"11-karboksy-delta-9-tetrahydrokannabinol (9-THC-COOH) 2", "NameInAPI"=>"11-nor-9-carboxy-delta9-tetrahydrocannabinol_2"},
     {"Id"=>995, "Name"=>"Hydroksyzyna (HDX) 1", "NameInReport"=>"Hydroksyzyna (HDX) 1", "NameInAPI"=>"hydroxyzine_1"},
     {"Id"=>1001, "Name"=>"Hydroksyzyna (HDX) 2", "NameInReport"=>"Hydroksyzyna (HDX) 2", "NameInAPI"=>"hydroxyzine_2"},
     {"Id"=>971, "Name"=>"Zolpidem (ZOL) 1", "NameInReport"=>"Zolpidem (ZOL) 1", "NameInAPI"=>"zolpidem_1"},
     {"Id"=>977, "Name"=>"Zolpidem (ZOL) 2", "NameInReport"=>"Zolpidem (ZOL) 2", "NameInAPI"=>"zolpidem_2"},
     {"Id"=>767, "Name"=>"Amfetamina (AMP) 1", "NameInReport"=>"Amfetamina (AMP) 1", "NameInAPI"=>"amphetamine_1"},
     {"Id"=>773, "Name"=>"Amfetamina (AMP) 2", "NameInReport"=>"Amfetamina (AMP) 2", "NameInAPI"=>"amphetamine_2"},
     {"Id"=>815, "Name"=>"Metamfetamina (METH) 1", "NameInReport"=>"Metamfetamina (METH) 1", "NameInAPI"=>"methamphetamine_1"},
     {"Id"=>821, "Name"=>"Metamfetamina (METH) 2", "NameInReport"=>"Metamfetamina (METH) 2", "NameInAPI"=>"methamphetamine_2"},
     {"Id"=>779, "Name"=>"3,4-metylenodioksyamfetamina (MDA) 1", "NameInReport"=>"3,4-metylenodioksyamfetamina (MDA) 1", "NameInAPI"=>"3,4-methylenedioxyamphetamine_1"},
     {"Id"=>785, "Name"=>"3,4-metylenodioksyamfetamina (MDA) 2", "NameInReport"=>"3,4-metylenodioksyamfetamina (MDA) 2", "NameInAPI"=>"3,4-methylenedioxyamphetamine_2"},
     {"Id"=>827, "Name"=>"3,4-metylenodioksymetamfetamina (MDMA) 1", "NameInReport"=>"3,4-metylenodioksymetamfetamina (MDMA) 1", "NameInAPI"=>"3,4-methylenedioxymethamphetamine_1"},
     {"Id"=>833, "Name"=>"3,4-metylenodioksymetamfetamina (MDMA) 2", "NameInReport"=>"3,4-metylenodioksymetamfetamina (MDMA) 2", "NameInAPI"=>"3,4-methylenedioxymethamphetamine_2"},
     {"Id"=>839, "Name"=>"3,4-metylenodioksy-N-etyloamfetamina (MDEA) 1", "NameInReport"=>"3,4-metylenodioksy-N-etyloamfetamina (MDEA) 1", "NameInAPI"=>"3,4-methylenedioxy-n-ethylamphetamine_1"},
     {"Id"=>845, "Name"=>"3,4-metylenodioksy-N-etyloamfetamina (MDEA) 2", "NameInReport"=>"3,4-metylenodioksy-N-etyloamfetamina (MDEA) 2", "NameInAPI"=>"3,4-methylenedioxy-n-ethylamphetamine_2"},
     {"Id"=>887, "Name"=>"Kokaina (COC) 1", "NameInReport"=>"Kokaina (COC) 1", "NameInAPI"=>"cocaine_1"},
     {"Id"=>893, "Name"=>"Kokaina (COC) 2", "NameInReport"=>"Kokaina (COC) 2", "NameInAPI"=>"cocaine_2"},
     {"Id"=>875, "Name"=>"Benzoiloekgonina (BEC) 1", "NameInReport"=>"Benzoiloekgonina (BEC) 1", "NameInAPI"=>"benzoylecgonine_1"},
     {"Id"=>881, "Name"=>"Benzoiloekgonina (BEC) 2", "NameInReport"=>"Benzoiloekgonina (BEC) 2", "NameInAPI"=>"benzoylecgonine_2"},
     {"Id"=>911, "Name"=>"Mefedron (4-MMC) 1", "NameInReport"=>"Mefedron (4-MMC) 1", "NameInAPI"=>"mephedrone_1"},
     {"Id"=>917, "Name"=>"Mefedron (4-MMC) 2", "NameInReport"=>"Mefedron (4-MMC) 2", "NameInAPI"=>"mephedrone_2"},
     {"Id"=>1103, "Name"=>"3-chlorometkatynon (3-CMC) 1", "NameInReport"=>"3-chlorometkatynon (3-CMC) 1", "NameInAPI"=>"3-chloromethcathinone_1"},
     {"Id"=>1109, "Name"=>"3-chlorometkatynon (3-CMC) 2", "NameInReport"=>"3-chlorometkatynon (3-CMC) 2", "NameInAPI"=>"3-chloromethcathinone_2"},
     {"Id"=>1115, "Name"=>"4-chlorometkatynon (4-CMC) 1", "NameInReport"=>"4-chlorometkatynon (4-CMC) 1", "NameInAPI"=>"4-chloromethcathinone_1"},
     {"Id"=>1121, "Name"=>"4-chlorometkatynon (4-CMC) 2", "NameInReport"=>"4-chlorometkatynon (4-CMC) 2", "NameInAPI"=>"4-chloromethcathinone_2"}] 


    [:whole_blood, :urine, :aqueous_humor, :blood_plasma, :blood_serum, :drainage].each do |m|
      joined.each do |h|
        analyte = Analyte.find_by(ProjectId: 39, material_type: m, NameInAPI: h["NameInAPI"])
        analyte.update(Name: h["Name"], NameInReport: h["NameInReport"])
        # analyte.write_attribute(:NameInReport, h["NameInReport"])
      end
    end


  end
end
