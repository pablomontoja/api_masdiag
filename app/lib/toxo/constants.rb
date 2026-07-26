module Toxo
  module Constants
    TOXO_PROJECT_IDS = [39, 40, 41, 42].freeze

    # TODO: uzupełnić właściwymi Institution.Id po ustaleniu z użytkownikiem — mirrors
    # toxo's ChromatogramRequest::ALLOWED_INSTITUTION_IDS (kept in sync manually)
    CHROMATOGRAM_REQUEST_INSTITUTION_IDS = [1, 142].freeze

    CHROMATOGRAM_REQUEST_NOTE_KEY = "chromatogram-request-email".freeze

    PROJECT_NAMES = {
      39 => "Analiza toksykologiczna ilościowa (LC-MS/MS)",
      40 => "Analiza toksykologiczna jakościowa (LC-MS/MS)",
      41 => "Analiza ilościowa kwasu γ-hydroksymasłowego (GHB) (LC-MS/MS)",
      42 => "Analiza toksykologiczna na zlecenie"
    }.freeze

    # project_ids logic: Qual (40) always pulls in Quant (39)
    def self.expand_project_ids(ids)
      ids = ids.map(&:to_i)
      ids |= [39] if ids.include?(40)
      ids & TOXO_PROJECT_IDS
    end
  end
end
