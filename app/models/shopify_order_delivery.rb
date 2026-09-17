class ShopifyOrderDelivery < ApplicationRecord
  serialize :payload, type: Hash, default: {}
  serialize :unmapped_product_ids, type: Array, default: nil
  serialize :resolved_project_ids, type: Array, default: nil

  enum :status, { pending: 0, processed: 1, blocked: 2, failed: 3 }

  validates :webhook_id, presence: true, uniqueness: true
  validates :shopify_order_id, presence: true
  validates :payload, presence: true

  scope :needs_attention, -> { where(status: [:blocked, :failed]) }
end
