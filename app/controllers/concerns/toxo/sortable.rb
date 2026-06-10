module Toxo
  module Sortable
    extend ActiveSupport::Concern

    ALLOWED_DIRECTIONS = %w[asc desc].freeze

    def apply_sort(relation)
      col = self.class::SORTABLE_COLUMNS[params[:sort]]
      dir = ALLOWED_DIRECTIONS.include?(params[:direction]) ? params[:direction] : nil
      return relation unless col && dir

      # MariaDB 10.1 does not support NULLS LAST; IS NULL evaluates to 0/1 keeping nulls last
      relation.order(Arel.sql("#{col} IS NULL, #{col} #{dir}"))
    end
  end
end
