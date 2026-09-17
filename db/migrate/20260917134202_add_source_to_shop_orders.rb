# shop_orders is a SHARED LabSample table, used by other apps beyond api_masdiag
# (indclients2, labpanel, order-panel, etc.) — confirmed with the user before writing this
# migration (see specs/011-shop-order-rsc-allocation/spec.md Clarifications). This is additive
# and backward-compatible: nullable, defaulted, no existing column touched — other apps that
# don't know about `source` are unaffected.
class AddSourceToShopOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_orders, :source, :string, default: "wordpress"
  end
end
