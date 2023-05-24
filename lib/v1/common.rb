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

  CURRENT_VERSION = "1.03"

  CURRENT_DOCUMENTATION_URL = "https://laboratoriummasdiag-my.sharepoint.com/:w:/g/personal/pawel_swider_masdiag_pl/ER55sN5uFclLqY065SatCqwBSIhFfZADtVtgiHyCZ8ugBg?e=v8KO3e"

  AVAILABLE_TESTS = [{id: 2, name: "Vitamin D metabolites", material: "DBS", weight: 1, comment:""},
                     {id: 3, name: "Aminoacids", material: "DBS", weight: 1, comment:""},
                     {id: 10, name: "Vitamin A, E and Coenzyme Q10", material: "DBS", weight: 1, comment:"A special DBS card is required"},
                     {id: 12, name: "Homocysteine", material: "DBS", weight: 1, comment:""},
                     {id: 13, name: "Borreliosis Screening", material: "DBS", weight: 1, comment:""},
                     {id: 14, name: "TSH", material: "DBS", weight: 2, comment:""},
                     {id: 15, name: "Organic acid profile", material: "urine", weight: 1, comment:""},
                     {id: 16, name: "Purines and Pyrimidines", material: "urine", weight: 1, comment:""},
                     {id: 17, name: "SAICAr and S-Ado", material: "urine", weight: 1, comment:""},
                     {id: 18, name: "Acylcarnitines", material: "DBS", weight: 1, comment:""},
                     {id: 19, name: "Borreliosis Confirmation", material: "DBS", weight: 1, comment:""}].freeze
end
