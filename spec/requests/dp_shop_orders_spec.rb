require 'rails_helper'
require 'json'
include ApiHelpers # source of correct_import

RSpec.describe 'DiagnostykaPrecyzyjna::ShopOrdersController', type: :request do
  describe 'POST /import' do

    # after(:each) do
    #   ShopOrder.destroy_all
    # end

    context 'with valid parameters' do
      let(:inst) { create(:institution, id: 33) }

      before do
        # Clean up any existing data that might interfere
        ReservedSampleCode.where(InstitutionId: inst.id).destroy_all
        ShopOrder.destroy_all

        stock = create(:stock_room_item)
        create(:reserved_sample_code, package: stock.storagable, IsRetailSale: false, InstitutionId: inst.id)
      end

      it 'returns success' do
        shop_order = build(:shop_order)
        allow(shop_order).to receive(:package_ids).and_return([1])
        allow(DiagnostykaPrecyzyjna::RegShopOrder).to receive(:call).and_return(OpenStruct.new(success?: true, payload: shop_order))
        post '/diagnostyka_precyzyjna/shop_orders', params: { _json: JSON.parse(correct_import) }, as: :json
        expect(response).to have_http_status(:success)
      end

      it 'add one shop_order' do
        shop_orders_count = ShopOrder.count
        shop_order = build(:shop_order)
        allow(shop_order).to receive(:package_ids).and_return([1])
        allow(DiagnostykaPrecyzyjna::RegShopOrder).to receive(:call).and_return(OpenStruct.new(success?: true, payload: shop_order))
        post '/diagnostyka_precyzyjna/shop_orders', params: { _json: JSON.parse(correct_import) }, as: :json
        expect(ShopOrder.count).to eq(shop_orders_count + 1)
      end
    end

    context 'valid parameters' do
      let(:inst) { create(:institution, id: 33) }

      before do
        # Clean up any existing data that might interfere
        ReservedSampleCode.where(InstitutionId: inst.id).destroy_all
        ShopOrder.destroy_all

        stock = create(:stock_room_item)
        create(:reserved_sample_code, package: stock.storagable, IsRetailSale: false, InstitutionId: inst.id)
        stock2 = create(:second_stock_room_item)
        create(:second_reserved_sample_code, package: stock2.storagable, IsRetailSale: false, InstitutionId: inst.id)
      end

      it 'add 2 kits if Quantity 2' do
        expect(DiagnostykaPrecyzyjna::RegShopOrder).to receive(:call).and_call_original
        expect {
          post '/diagnostyka_precyzyjna/shop_orders', params: { _json: JSON.parse(two_kits_correct_import) }, as: :json
        }.to change { ShopOrder.count }.by(1)

        shop_order = assigns(:shop_order).reload
        expect(shop_order.reserved_sample_codes.count).to eq(2)
        expect(assigns(:errors).count).to eq(0)
      end

      it 'enqueue IndMailer after_new_order_save' do
        expect{ post '/diagnostyka_precyzyjna/shop_orders', params: { _json: JSON.parse(two_kits_correct_import) }, as: :json }.to have_enqueued_job(MasdiagMailDeliveryJob).with("MasdiagMailer::IndMailer", "after_new_order_save", "deliver_now", hash_including(:args))
      end

      it 'enqueue IndMailer shipping_after_new_order' do
        expect{ post '/diagnostyka_precyzyjna/shop_orders', params: { _json: JSON.parse(two_kits_correct_import) }, as: :json }.to have_enqueued_job(MasdiagMailDeliveryJob).with("MasdiagMailer::IndMailer", "shipping_after_new_order", "deliver_now", hash_including(:args))
      end

    end

    context 'with invalid parameters' do
      it 'returns success with lack of email error' do
        expect(DiagnostykaPrecyzyjna::RegShopOrder).to receive(:call).and_call_original
        post '/diagnostyka_precyzyjna/shop_orders', params: { _json: JSON.parse(incorrect_import) }, as: :json
        expect(assigns(:errors).count).to eq(1)
        expect(assigns(:errors).flatten.join(" ")).to include("Nie przekazano adresu email lub jest on zablokowany!")
        expect(response).to have_http_status(:success)
      end
    end

    context 'lack of packages in stock' do
      let(:inst) { create(:institution, id: 33) }

      before do
        # Clean up any existing RSCs that might interfere
        ReservedSampleCode.where(InstitutionId: inst.id).destroy_all
        ShopOrder.destroy_all

        # Create a package but mark it as already used (date_out set)
        stock = create(:stock_room_item, date_out: Time.current)
        create(:reserved_sample_code,
               package: stock.storagable,
               IsRetailSale: false,
               InstitutionId: inst.id)
      end

      it 'returns error when no packages in stock' do
        expect{ post '/diagnostyka_precyzyjna/shop_orders', params: { _json: JSON.parse(correct_import) }, as: :json }.to change { ShopOrder.count }.by(0)
        expect(assigns(:errors).flatten.join(" ")).to include("Serwer API w aplikacji INDCLIENTS2 nie jest w stanie znaleźć ani jednego dostępnego pudełka na magazynie.")
      end
    end

  end
end
