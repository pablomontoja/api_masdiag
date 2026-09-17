# == Schema Information
#
# Table name: shopify_order_deliveries
#
#  id                   :bigint           not null, primary key
#  webhook_id           :string(255)      not null
#  shopify_order_id     :string(255)      not null
#  event_type           :string(255)      default("orders/paid"), not null
#  payload              :text(16777215)   not null
#  status               :integer          default(0), not null
#  failure_reason       :text(65535)
#  unmapped_product_ids :text(65535)
#  resolved_project_ids :text(65535)
#  processed_at         :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  shop_order_id        :bigint
#
class ShopifyOrderDelivery < ApplicationRecord
  serialize :payload, type: Hash, default: {}
  serialize :unmapped_product_ids, type: Array, default: nil
  serialize :resolved_project_ids, type: Array, default: nil

  belongs_to :shop_order, optional: true

  enum :status, { pending: 0, processed: 1, blocked: 2, failed: 3 }

  validates :webhook_id, presence: true, uniqueness: true
  validates :shopify_order_id, presence: true
  validates :payload, presence: true

  scope :needs_attention, -> { where(status: [:blocked, :failed]) }
end
