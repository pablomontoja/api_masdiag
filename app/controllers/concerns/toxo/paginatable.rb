module Toxo
  module Paginatable
    extend ActiveSupport::Concern
    include Pagy::Backend

    DEFAULT_PER_PAGE = 25

    def paginate(relation)
      pagy, records = pagy(relation, page: params[:page], items: params[:per_page] || DEFAULT_PER_PAGE)
      meta = {
        page: pagy.page,
        per_page: pagy.items,
        total_count: pagy.count,
        total_pages: pagy.pages
      }
      [ records, meta ]
    end
  end
end
