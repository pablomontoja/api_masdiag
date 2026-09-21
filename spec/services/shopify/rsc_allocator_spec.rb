require 'rails_helper'

RSpec.describe Shopify::RscAllocator do
  describe '.call' do
    context 'when an eligible Package/ReservedSampleCode exists' do
      let!(:institution) { create(:institution, id: 33) }
      let!(:project) { create(:project) } # Id 2
      let!(:project2) { create(:project2) } # Id 3
      let(:stock_room_item) { create(:stock_room_item) }
      let!(:reserved_sample_code) do
        create(:reserved_sample_code, package: stock_room_item.storagable, IsRetailSale: false, InstitutionId: nil)
      end

      it 'allocates the ReservedSampleCode, tagging institution and retail-sale flags' do
        rsc = described_class.call([2], inst_id: 33)

        expect(rsc).to eq(reserved_sample_code)
        expect(rsc.reload.IsRetailSale).to eq(true)
        expect(rsc.InstitutionId).to eq(33)
      end

      it 'creates one ReservedTest per project id' do
        rsc = described_class.call([2], inst_id: 33)

        expect(rsc.reserved_tests.count).to eq(1)
        expect(rsc.reserved_tests.pluck(:project_id)).to eq([2])
      end

      it 'creates one ReservedTest per project id when the kit has multiple project ids (bundle)' do
        rsc = described_class.call([2, 3], inst_id: 33)

        expect(rsc.reserved_tests.count).to eq(2)
        expect(rsc.reserved_tests.pluck(:project_id)).to match_array([2, 3])
      end
    end

    context 'when no eligible Package/ReservedSampleCode exists' do
      it 'returns nil without raising' do
        expect(described_class.call([2], inst_id: 33)).to be_nil
      end
    end

    context 'when the only available Package is already out of stock' do
      let(:stock_room_item) { create(:stock_room_item, remaining_quantity: 1, date_out: Time.current) }
      let!(:reserved_sample_code) do
        create(:reserved_sample_code, package: stock_room_item.storagable, IsRetailSale: false, InstitutionId: nil)
      end

      it 'returns nil' do
        expect(described_class.call([2], inst_id: 33)).to be_nil
      end
    end

    context 'when the only available Package is expired within the lead time' do
      let(:package) { create(:package, expiry_date: 1.month.from_now) }
      let(:stock_room_item) { create(:stock_room_item, storagable: package) }
      let!(:reserved_sample_code) do
        create(:reserved_sample_code, package: package, IsRetailSale: false, InstitutionId: nil)
      end

      it 'returns nil (excluded by the 6-month expiry lead-time window)' do
        expect(described_class.call([2], inst_id: 33)).to be_nil
      end
    end
  end
end
