class BackfillProjectEnglishNames < ActiveRecord::Migration[8.0]
  # English name per Project Id. Source is Projects.eng_name where that value is
  # genuinely an English name (see specs/012-project-name-translation/data-model.md
  # for the source (E/C) rationale behind every row); everywhere else the name is
  # hand-curated. Values below were captured from the current development database
  # (which mirrors production) immediately before writing this migration.
  ENGLISH_NAMES = {
    1  => "Newborn Screening",                          # C — eng_name "NBS" is an acronym, expanded for clarity
    2  => "Vitamin D metabolites",                       # E
    3  => "Aminoacids",                                  # E
    4  => "Archive",                                     # C — eng_name blank
    5  => "AED",                                         # E — acronym, identical in both languages
    6  => "CBD",                                         # E — acronym, identical in both languages
    7  => "Psychoactive Substances Panel",                # C — eng_name "TOXO" is an internal category code, not a translation
    8  => "EDX",                                         # E — acronym, identical in both languages
    9  => "anty-SARS-CoV-2 antibodies",                   # E
    10 => "Vitamin A, E and Coenzyme Q10",                # E
    11 => "CBD/THC",                                      # C — eng_name "THC" only covers half the Polish name
    12 => "Homocysteine",                                 # E
    13 => "Borreliosis Screening",                        # E — already English
    14 => "TSH",                                          # E — acronym, identical in both languages
    15 => "Organic acid profile",                         # E
    16 => "Purines and Pyrimidines",                      # E
    17 => "SAICAr and S-Ado",                             # E
    18 => "Acylcarnitines",                               # E
    19 => "Borreliosis Confirmation",                     # E — already English
    20 => "Methanephrines",                               # E
    21 => "OMEGA Acids",                                  # E
    22 => "Vitamin D",                                    # E
    23 => "HbA1c",                                        # E — acronym, identical in both languages
    24 => "Histamine Intolerance",                        # E
    25 => "3-OMD TEST",                                   # E — acronym, identical in both languages
    26 => "Glutathione Index",                            # C — eng_name "GSSG:GSH_ratio" is a technical ratio label, not a translation
    27 => "Phosphatidylethanol",                          # E
    28 => "Goldcup TOX",                                  # E — already English
    29 => "Iodine in urine",                              # E
    30 => "Arginase deficiency",                          # E
    31 => "Toxicology",                                   # E
    32 => "Metals in urine",                              # E
    33 => "ALD-X",                                        # C — eng_name is a product/panel code, kept as the recognized English-facing name
    34 => "OMEGA Acids Basic",                            # E
    35 => "Lysosphingomyelins",                           # C — eng_name "Lyso" is an abbreviation, not a full translation
    36 => "NAD",                                          # E — acronym, identical in both languages
    37 => "Amino acid profile in urine",                  # E
    38 => "Steroid profile",                              # E
    39 => "Quantitative toxicological analysis",          # E
    40 => "Qualitative toxicological analysis",           # E
    41 => "GHB toxicological analysis",                   # E
    42 => "Custom Toxicological Analysis",                # E
    43 => "LysoGb1",                                      # C — eng_name blank; Polish name is already an English-style identifier
    44 => "LysoGb3",                                      # C — eng_name blank; Polish name is already an English-style identifier
    45 => "Magnesium",                                    # C — eng_name blank
    46 => "PAGN",                                         # E — acronym, identical in both languages
    47 => "PAGN in urine"                                 # E
  }.freeze

  def up
    ENGLISH_NAMES.each do |id, english_name|
      project = Project.find_by(Id: id)
      next if project.nil?
      next if project.read_attribute(:Name).blank?

      project.public_send(:Name=, english_name, locale: :en)
      project.save!
    end
  end

  def down
    ActiveRecord::Base.connection.execute(
      "DELETE FROM mobility_string_translations WHERE translatable_type = 'Project' AND `key` = 'Name' AND locale = 'en'"
    )
  end
end
