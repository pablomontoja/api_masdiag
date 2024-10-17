# This class is used only by scripts in /script folder (2024-08-22)
class ProductionOrdersJob < ApplicationJob

  def perform(production_order_params, current_user)
    @production_order = ProductionOrder.new(production_order_params)
    @production_order = Masdiag::PackagesCreator.call(@production_order).payload
    res = Masdiag::ReservedSampleCodesCreator.call(@production_order, current_user)

    if res.success?
      @production_order = res.payload
    end

    @production_order.save
  end

end
