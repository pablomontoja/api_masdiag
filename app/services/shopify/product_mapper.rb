module Shopify
  class ProductMapper
    CONFIG_PATH = Rails.root.join("config", "shopify_product_mappings.yml")

    class << self
      def project_ids_for(variant_id)
        mapping.fetch(variant_id.to_s, [])
      end

      # Raises if any configured Project id no longer exists — catches drift
      # between config/shopify_product_mappings.yml and the LabSample Projects
      # table without silently mis-mapping an order to a stale test.
      def validate_targets!
        configured_ids = mapping.values.flatten.uniq
        missing = configured_ids - Project.where(Id: configured_ids).pluck(:Id)
        raise "shopify_product_mappings.yml references unknown Project id(s): #{missing.join(', ')}" if missing.any?
      end

      def mapping
        @mapping ||= YAML.load_file(CONFIG_PATH) || {}
      end
    end
  end
end
