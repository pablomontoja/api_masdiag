class ToxoQuantEngNamesImport < ActiveRecord::Migration[7.1]
  def change
    I18n.locale = :en

    joined = [
      {"Id"=>1067, "Name"=>"Oksykodon 1", "NameInReport"=>"Oxycodone 1", "NameInAPI"=>"oxycodone_1"},
      {"Id"=>1073, "Name"=>"Oksykodon 2", "NameInReport"=>"Oxycodone 2", "NameInAPI"=>"oxycodone_2"},
      {"Id"=>1079, "Name"=>"Oksymorfon 1", "NameInReport"=>"Oxymorphone 1", "NameInAPI"=>"oxymorphone_1"},
      {"Id"=>1085, "Name"=>"Oksymorfon 2", "NameInReport"=>"Oxymorphone 2", "NameInAPI"=>"oxymorphone_2"},
      {"Id"=>1091, "Name"=>"Noroksykodon 1", "NameInReport"=>"Noroxycodone 1", "NameInAPI"=>"noroxycodone_1"},
      {"Id"=>1097, "Name"=>"Noroksykodon 2", "NameInReport"=>"Noroxycodone 2", "NameInAPI"=>"noroxycodone_2"},
      {"Id"=>791, "Name"=>"Morfina 1", "NameInReport"=>"Morphine 1", "NameInAPI"=>"morphine_1"},
      {"Id"=>797, "Name"=>"Morfina 2", "NameInReport"=>"Morphine 2", "NameInAPI"=>"morphine_2"},
      {"Id"=>803, "Name"=>"Kodeina 1", "NameInReport"=>"Codeine 1", "NameInAPI"=>"codeine_1"},
      {"Id"=>809, "Name"=>"Kodeina 2", "NameInReport"=>"Codeine 2", "NameInAPI"=>"codeine_2"},
      {"Id"=>851, "Name"=>"6-monoacetylomorfina 1", "NameInReport"=>"6-Acetylomorphine 1", "NameInAPI"=>"6-acetylmorphine_1"},
      {"Id"=>857, "Name"=>"6-monoacetylomorfina 2", "NameInReport"=>"6-Acetylomorphine 2", "NameInAPI"=>"6-acetylmorphine_2"},
      {"Id"=>947, "Name"=>"Fentanyl 1", "NameInReport"=>"Fentanyl 1", "NameInAPI"=>"fentanyl_1"},
      {"Id"=>953, "Name"=>"Fentanyl 2", "NameInReport"=>"Fentanyl 2", "NameInAPI"=>"fentanyl_2"},
      {"Id"=>863, "Name"=>"Tramadol 1", "NameInReport"=>"Tramadol 1", "NameInAPI"=>"tramadol_1"},
      {"Id"=>869, "Name"=>"Tramadol 2", "NameInReport"=>"Tramadol 2", "NameInAPI"=>"tramadol_2"},
      {"Id"=>1031, "Name"=>"Metadon 1", "NameInReport"=>"Methadone 1", "NameInAPI"=>"methadone_1"},
      {"Id"=>1037, "Name"=>"Metadon 2", "NameInReport"=>"Methadone 2", "NameInAPI"=>"methadone_2"},
      {"Id"=>899, "Name"=>"Klonazepam 1", "NameInReport"=>"Clonazepam 1", "NameInAPI"=>"clonazepam_1"},
      {"Id"=>905, "Name"=>"Klonazepam 2", "NameInReport"=>"Clonazepam 2", "NameInAPI"=>"clonazepam_2"},
      {"Id"=>923, "Name"=>"7-aminoklonazepam 1", "NameInReport"=>"7-Aminoclonazepam 1", "NameInAPI"=>"7-aminoclonazepam_1"},
      {"Id"=>929, "Name"=>"7-aminoklonazepam 2", "NameInReport"=>"7-Aminoclonazepam 2", "NameInAPI"=>"7-aminoclonazepam_2"},
      {"Id"=>935, "Name"=>"Flunitrazepam 1", "NameInReport"=>"Flunitrazepam 1", "NameInAPI"=>"flunitrazepam_1"},
      {"Id"=>941, "Name"=>"Flunitrazepam 2", "NameInReport"=>"Flunitrazepam 2", "NameInAPI"=>"flunitrazepam_2"},
      {"Id"=>959, "Name"=>"7-aminoflunitrazepam 1", "NameInReport"=>"7-Aminoflunitrazepam 1", "NameInAPI"=>"7-aminoflunitrazepam_1"},
      {"Id"=>965, "Name"=>"7-aminoflunitrazepam 2", "NameInReport"=>"7-Aminoflunitrazepam 2", "NameInAPI"=>"7-aminoflunitrazepam_2"},
      {"Id"=>983, "Name"=>"Lorazepam 1", "NameInReport"=>"Lorazepam 1", "NameInAPI"=>"lorazepam_1"},
      {"Id"=>989, "Name"=>"Lorazepam 2", "NameInReport"=>"Lorazepam 2", "NameInAPI"=>"lorazepam_2"},
      {"Id"=>1043, "Name"=>"Diazepam 1", "NameInReport"=>"Diazepam 1", "NameInAPI"=>"diazepam_1"},
      {"Id"=>1049, "Name"=>"Diazepam 2", "NameInReport"=>"Diazepam 2", "NameInAPI"=>"diazepam_2"},
      {"Id"=>1007, "Name"=>"Nordiazepam 1", "NameInReport"=>"Nordiazepam 1", "NameInAPI"=>"nordiazepam_1"},
      {"Id"=>1013, "Name"=>"Nordiazepam 2", "NameInReport"=>"Nordiazepam 2", "NameInAPI"=>"nordiazepam_2"},
      {"Id"=>1019, "Name"=>"Oksazepam 1", "NameInReport"=>"Oxazepam 1", "NameInAPI"=>"oxazepam_1"},
      {"Id"=>1025, "Name"=>"Oksazepam 2", "NameInReport"=>"Oxazepam 2", "NameInAPI"=>"oxazepam_2"},
      {"Id"=>1055, "Name"=>"Alprazolam 1", "NameInReport"=>"Alprazolam 1", "NameInAPI"=>"alprazolam_1"},
      {"Id"=>1061, "Name"=>"Alprazolam 2", "NameInReport"=>"Alprazolam 2", "NameInAPI"=>"alprazolam_2"},
      {"Id"=>1139, "Name"=>"CBD 1", "NameInReport"=>"CBD 1", "NameInAPI"=>"cannabidiol (cbd)_1"},
      {"Id"=>1145, "Name"=>"CBD 2", "NameInReport"=>"CBD 2", "NameInAPI"=>"cannabidiol (cbd)_2"},
      {"Id"=>1127, "Name"=>"9-THC 1", "NameInReport"=>"THC 1", "NameInAPI"=>"delta9-tetrahydrocannabinol (delta-9thc)_1"},
      {"Id"=>1133, "Name"=>"9-THC 2", "NameInReport"=>"THC 2", "NameInAPI"=>"delta9-tetrahydrocannabinol (delta-9thc)_2"},
      {"Id"=>1163, "Name"=>"9-THC-OH 1", "NameInReport"=>"THC-OH 1", "NameInAPI"=>"11-nor-9-hydoxy-delta9-tetrahydrocannabinol_1"},
      {"Id"=>1169, "Name"=>"9-THC-OH 2", "NameInReport"=>"THC-OH 2", "NameInAPI"=>"11-nor-9-hydoxy-delta9-tetrahydrocannabinol_2"},
      {"Id"=>1151, "Name"=>"9-THC-COOH 1", "NameInReport"=>"THC-COOH 1", "NameInAPI"=>"11-nor-9-carboxy-delta9-tetrahydrocannabinol_1"},
      {"Id"=>1157, "Name"=>"9-THC-COOH 2", "NameInReport"=>"THC-COOH 2", "NameInAPI"=>"11-nor-9-carboxy-delta9-tetrahydrocannabinol_2"},
      {"Id"=>995, "Name"=>"Hydroksyzyna 1", "NameInReport"=>"Hydroxyzine 1", "NameInAPI"=>"hydroxyzine_1"},
      {"Id"=>1001, "Name"=>"Hydroksyzyna 2", "NameInReport"=>"Hydroxyzine 2", "NameInAPI"=>"hydroxyzine_2"},
      {"Id"=>971, "Name"=>"Zolpidem 1", "NameInReport"=>"Zolpidem 1", "NameInAPI"=>"zolpidem_1"},
      {"Id"=>977, "Name"=>"Zolpidem 2", "NameInReport"=>"Zolpidem 2", "NameInAPI"=>"zolpidem_2"},
      {"Id"=>767, "Name"=>"Amfetamina 1", "NameInReport"=>"Amphetamine 1", "NameInAPI"=>"amphetamine_1"},
      {"Id"=>773, "Name"=>"Amfetamina 2", "NameInReport"=>"Amphetamine 2", "NameInAPI"=>"amphetamine_2"},
      {"Id"=>815, "Name"=>"Metamfetamina 1", "NameInReport"=>"Methamphetamine 1", "NameInAPI"=>"methamphetamine_1"},
      {"Id"=>821, "Name"=>"Metamfetamina 2", "NameInReport"=>"Methamphetamine 2", "NameInAPI"=>"methamphetamine_2"},
      {"Id"=>779, "Name"=>"MDA 1", "NameInReport"=>"MDA 1", "NameInAPI"=>"3,4-methylenedioxyamphetamine_1"},
      {"Id"=>785, "Name"=>"MDA 2", "NameInReport"=>"MDA 2", "NameInAPI"=>"3,4-methylenedioxyamphetamine_2"},
      {"Id"=>827, "Name"=>"MDMA 1", "NameInReport"=>"MDMA 1", "NameInAPI"=>"3,4-methylenedioxymethamphetamine_1"},
      {"Id"=>833, "Name"=>"MDMA 2", "NameInReport"=>"MDMA 2", "NameInAPI"=>"3,4-methylenedioxymethamphetamine_2"},
      {"Id"=>839, "Name"=>"MDEA 1", "NameInReport"=>"MDEA 1", "NameInAPI"=>"3,4-methylenedioxy-n-ethylamphetamine_1"},
      {"Id"=>845, "Name"=>"MDEA 2", "NameInReport"=>"MDEA 2", "NameInAPI"=>"3,4-methylenedioxy-n-ethylamphetamine_2"},
      {"Id"=>887, "Name"=>"Kokaina 1", "NameInReport"=>"Cocaine 1", "NameInAPI"=>"cocaine_1"},
      {"Id"=>893, "Name"=>"Kokaina 2", "NameInReport"=>"Cocaine 2", "NameInAPI"=>"cocaine_2"},
      {"Id"=>875, "Name"=>"Benzoiloekgonina 1", "NameInReport"=>"Benzoylecgonine 1", "NameInAPI"=>"benzoylecgonine_1"},
      {"Id"=>881, "Name"=>"Benzoiloekgonina 2", "NameInReport"=>"Benzoylecgonine 2", "NameInAPI"=>"benzoylecgonine_2"},
      {"Id"=>911, "Name"=>"Mefedron 1", "NameInReport"=>"4-MMC 1", "NameInAPI"=>"mephedrone_1"},
      {"Id"=>917, "Name"=>"Mefedron 2", "NameInReport"=>"4-MMC 2", "NameInAPI"=>"mephedrone_2"},
      {"Id"=>1103, "Name"=>"3-CMC 1", "NameInReport"=>"3-CMC 1", "NameInAPI"=>"3-chloromethcathinone_1"},
      {"Id"=>1109, "Name"=>"3-CMC 2", "NameInReport"=>"3-CMC 2", "NameInAPI"=>"3-chloromethcathinone_2"},
      {"Id"=>1115, "Name"=>"4-CMC 1", "NameInReport"=>"4-CMC 1", "NameInAPI"=>"4-chloromethcathinone_1"},
      {"Id"=>1121, "Name"=>"4-CMC 2", "NameInReport"=>"4-CMC 2", "NameInAPI"=>"4-chloromethcathinone_2"}
    ]



    [:whole_blood, :urine, :aqueous_humor, :blood_plasma, :blood_serum, :drainage].each do |m|
      joined.each do |h|
        analyte = Analyte.find_by(ProjectId: 39, material_type: m, NameInAPI: h["NameInAPI"])
        analyte.update(NameInReport: h["NameInReport"])
      end
    end
  end
end
