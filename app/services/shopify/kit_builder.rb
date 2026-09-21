module Shopify
  class KitBuilder < ApplicationService
    Kit = Struct.new(:project_ids)

    def initialize(line_items)
      @line_items = line_items
    end

    def call
      @line_items.flat_map do |item|
        quantity = item["quantity"].to_i
        Array.new(quantity) { Kit.new(item["project_ids"]) }
      end
    end
  end
end
