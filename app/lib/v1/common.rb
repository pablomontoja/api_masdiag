module V1::Common
  IDENTITY_DOCUMENTS = {
    1 => "paszport",
    2 => "karta pobytu",
    3 => "polski dokument tożsamości cudzoziemca",
    4 => "tymczasowe zaświadczenie tożsamości cudzoziemca",
    5 => "dokument podróży (status uchodźcy konw. genewska)",
    6 => "zgoda na pobyt tolerowany",
    7 => "PESEL opiekuna prawnego gdy pacjentem jest noworodek"
  }.freeze

  CURRENT_VERSION = "1.07"

  # TODO lista instytucji Lalena nie moze byc w kodzie aplikacji
  LALEN_INSTITUTION_IDS = [83, 85, 89, 93, 95]

  # Instytucje należące do systemu Toxo (toxo.masdiag.pl). Dla próbek tych
  # instytucji system powiadomień wybiera szablon Toxo zamiast standardowego
  # szablonu laboratoryjnego (patrz Notifications::TemplateResolver).
  # TODO uzupełnić właściwymi id instytucji Toxo z konfiguracji puli kodów;
  # TODO lista instytucji Toxo nie powinna docelowo być w kodzie aplikacji
  TOXO_INSTITUTION_IDS = [133, 141, 142, 143, 144, 145].freeze

  # Adres portalu partnerskiego Toxo (używany w treści powiadomień C, D, F).
  TOXO_PARTNER_PORTAL_URL = "toxo.masdiag.pl"

  CURRENT_DOCUMENTATION_URL = "https://laboratoriummasdiag-my.sharepoint.com/:w:/g/personal/pawel_swider_masdiag_pl/EenLLdV5t-dMk71yga-TJiMBlPd9c8jwnHHVD6M4tPWSUg?e=sKEq5c"
  FV1_CURRENT_DOCUMENTATION_URL = "https://laboratoriummasdiag-my.sharepoint.com/:w:/g/personal/pawel_swider_masdiag_pl/EfgjGaaBxYpFmFcWI7A50WIBLuzELM0NPUfCEvYilzsXaw?e=ezJUtw"
  NUME_CURRENT_DOCUMENTATION_URL = "https://laboratoriummasdiag-my.sharepoint.com/:w:/g/personal/pawel_swider_masdiag_pl/ESuHUfA4IxlNnWdO7NDeyVABRgMAGFLDSY2hite7jJeKGQ?e=GItJh0"

  AVAILABLE_TESTS = [
                     {id: 2, name: "Vitamin D metabolites", material: "DBS", weight: 1, comment: ""},
                     {id: 3, name: "Aminoacids", material: "DBS", weight: 1, comment: ""},
                     {id: 10, name: "Vitamin A, E and Coenzyme Q10", material: "DBS", weight: 1, comment: "A special DBS card is required"},
                     {id: 12, name: "Homocysteine", material: "DBS", weight: 1, comment: ""},
                     {id: 15, name: "Organic acid profile", material: "urine", weight: 1, comment: ""},
                     {id: 16, name: "Purines and Pyrimidines", material: "urine", weight: 1, comment: ""},
                     {id: 17, name: "SAICAr and S-Ado", material: "urine", weight: 1, comment: ""},
                     {id: 18, name: "Acylcarnitines", material: "DBS", weight: 1, comment: ""},                    
                     {id: 21, name: "Omega Acids", material: "DBS", weight: 1, comment: "A special DBS card is required"},
                     {id: 22, name: "Vitamin D", material: "DBS", weight: 1, comment: ""},
                     {id: 23, name: "HbA1c", material: "DBS", weight: 1, comment: ""},
                     {id: 26, name: "GSSG/GSH - Glutathione Index", material: "DBS", weight: 2, comment: "A special DBS card is required"},
                     {id: 27, name: "Phosphatidylethanol", material: "DBS", weight: 1, comment: "Capitainer B50 card is required"},
                     {id: 28, name: "Goldcup TOXO", material: "DBS", weight: 1, comment: "Capitainer B50 card is required"},
                     {id: 34, name: "Omega-3 Index", material: "DBS", weight: 1, comment: "A special DBS card is required"}
                   ].freeze

  LALEN_TEST_API_KEYS = {
    22 => "vitamin-d",
    21 => "omega-3-basic",
    23 => "hba1c",
    12 => "homocysteine",
    26 => "glutathione-index"
  }.freeze
end

# {id: 14, name: "TSH", material: "DBS", weight: 2, comment: ""},
# {id: 13, name: "Borreliosis Screening", material: "DBS", weight: 1, comment: ""},
# {id: 19, name: "Borreliosis Confirmation", material: "DBS", weight: 1, comment: ""},