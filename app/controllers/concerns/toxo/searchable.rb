module Toxo
  module Searchable
    extend ActiveSupport::Concern

    def apply_search(relation)
      columns = self.class::SEARCHABLE_COLUMNS
      query = params[:q].to_s.strip
      return relation if query.blank?

      conditions = columns.map { |col| "#{col} LIKE :q" }.join(" OR ")
      relation.where(conditions, q: "%#{query}%")
    end
  end
end
