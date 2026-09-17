require 'rails_helper'

RSpec.describe Shopify::KitBuilder do
  describe '.call' do
    it 'produces one Kit per unit of quantity, each carrying the full project_ids' do
      line_items = [
        { "product_id" => "1", "quantity" => 2, "project_ids" => [18, 3] }
      ]

      kits = described_class.call(line_items)

      expect(kits.size).to eq(2)
      expect(kits.map(&:project_ids)).to eq([[18, 3], [18, 3]])
    end

    it 'produces zero kits for a line item with quantity 0' do
      line_items = [{ "product_id" => "1", "quantity" => 0, "project_ids" => [2] }]

      expect(described_class.call(line_items)).to eq([])
    end

    it 'produces zero kits for a line item with missing quantity' do
      line_items = [{ "product_id" => "1", "project_ids" => [2] }]

      expect(described_class.call(line_items)).to eq([])
    end

    it 'preserves separate groupings across multiple line items (not merged/deduped)' do
      line_items = [
        { "product_id" => "1", "quantity" => 1, "project_ids" => [25] },
        { "product_id" => "2", "quantity" => 1, "project_ids" => [18, 3] }
      ]

      kits = described_class.call(line_items)

      expect(kits.map(&:project_ids)).to contain_exactly([25], [18, 3])
    end
  end
end
