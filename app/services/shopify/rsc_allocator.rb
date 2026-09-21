module Shopify
  class RscAllocator < ApplicationService
    def initialize(project_ids, opts = {})
      @project_ids = project_ids
      @inst_id = opts[:inst_id]
    end

    def call
      rsc = eligible_relation
        .where(package: { stock_room_items: { storagable_type: "Package", remaining_quantity: 1, date_out: nil } })
        .where(package: { products: { type: 1 } })
        .where(package: { expiry_date: (Time.current + 6.months).. })
        .where(MaterialType: material_type)
        .where(material_handler: material_handler)
        .order('package.serial_number': :asc)
        .references(:packages, :products).limit(1).first

      return nil if rsc.nil?

      rsc.update!(IsRetailSale: true, InstitutionId: @inst_id)
      @project_ids.each { |proj| rsc.reserved_tests.create(project_id: proj) }
      rsc
    end

    private

    def eligible_relation
      base = ReservedSampleCode.includes(package: :stock_room_item).includes(package: :product)
      return base.where(package: { products: { id: 29 } }) if (@project_ids & [31]).any?

      base.where.not(package: { products: { id: 29 } })
    end

    # { dbs: 0, blood_serum: 1, blood_plasma: 2, hairs: 3, nails: 4, urine: 5, saliva: 6 }
    def material_type
      material = 0
      material = 5 if (@project_ids & [15, 16, 17, 31]).any?
      material
    end

    # { dbs_t4: 0, dbs_t5: 1, dbs_b4: 2, dbs_b5: 3, dbs_f4: 4, urine_vial: 5 }
    def material_handler
      handler = 0
      handler = 4 if (@project_ids & [21, 34]).any? # kwasy OMEGA
      handler = 5 if (@project_ids & [15, 16, 17, 29, 31, 32]).any? # mocze
      handler
    end
  end
end
