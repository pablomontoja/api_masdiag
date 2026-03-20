module Toxo
  TOXO_PROJECT_IDS = [39, 40, 41, 42].freeze

  PROJECT_NAMES = {
    39 => "Toxo IgG",
    40 => "Toxo IgM",
    41 => "Toxo GHB",
    42 => "Toxo Avidit"
  }.freeze

  # project_ids logic: IgM (40) always pulls in IgG (39)
  def self.expand_project_ids(ids)
    ids = ids.map(&:to_i)
    ids |= [39] if ids.include?(40)
    ids & TOXO_PROJECT_IDS
  end
end
