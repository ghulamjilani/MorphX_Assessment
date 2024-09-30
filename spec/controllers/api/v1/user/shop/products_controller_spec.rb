# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Shop::ProductsController do
  let(:session) { create(:immersive_session) }
  let(:current_user) { session.presenter.user }
  let(:list) { create(:list, organization: current_user.organization) }
  let(:lists_product) { create(:lists_product, list: list, product: create(:product, organization: current_user.organization)) }
  let(:product) { lists_product.product }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  render_views

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET show:' do
      before do
        get :show, params: { id: product.id }, format: :json
      end

      it { expect(response).to be_successful }
    end

    describe 'PUT update:' do
      before do
        put :update, params: { id: product.id, product: { title: 'New title' } }, format: :json
      end

      it { expect(response).to be_successful }
    end

    describe 'DELETE destroy:' do
      before do
        delete :destroy, params: { id: product.id }, format: :json
      end

      it { expect(response).to be_successful }
    end

    describe 'POST search_by_upc:' do
      before do
        post :search_by_upc,
             params: { barcode: product.barcodes.scan(/[0-9]+/).sample, session_id: session.id, list_id: list.id }, format: :json
      end

      it { expect(response).to be_successful }
    end
  end
end
