# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Shop::ProductsController do
  let(:list) { create(:list, selected: [true, false].sample) }

  describe '.json request format' do
    describe 'GET index:' do
      before do
        get :index, params: params, format: :json
      end

      context 'when given no params' do
        let(:params) { {} }

        it { expect(response).not_to be_successful }
      end

      context 'when given list_id param' do
        let(:list) { create(:lists_product).list }
        let(:params) { { list_id: list.id } }

        it { expect(response).to be_successful }
      end

      context 'when given order, order_by, limit and offset params' do
        let(:list) { create(:lists_product).list }
        let(:params) do
          {
            list_id: list.id,
            order: 'desc',
            order_by: 'updated_at',
            limit: 1,
            offset: 1
          }
        end

        it { expect(response).to be_successful }
      end
    end

    describe 'GET show:' do
      let(:product) { create(:product) }

      before do
        get :show, params: { id: product.id }, format: :json
      end

      it { expect(response).to be_successful }
    end
  end
end
