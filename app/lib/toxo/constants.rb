module Toxo
  module Constants
    TOXO_PROJECT_IDS = [39, 40, 41, 42].freeze

    PROJECT_NAMES = {
      39 => "Toxo Quant",
      40 => "Toxo Qual",
      41 => "Toxo GHB",
      42 => "Toxo NonStandard"
    }.freeze

    # project_ids logic: Qual (40) always pulls in Quant (39)
    def self.expand_project_ids(ids)
      ids = ids.map(&:to_i)
      ids |= [39] if ids.include?(40)
      ids & TOXO_PROJECT_IDS
    end
  end
end
