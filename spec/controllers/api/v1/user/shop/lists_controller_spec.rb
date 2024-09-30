# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Shop::ListsController do
  let(:list) { create(:list, selected: [true, false].sample) }
  let(:organization) { list.organization }
  let(:current_user) { organization.user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

  describe '.json request format' do
    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      before do
        get :index, params: params, format: :json
      end

      context 'when given no params' do
        let(:params) { {} }

        it { expect(response).to be_successful }
      end

      context 'when given recording_id param' do
        let(:attached_list) { create(:attached_list, model: create(:recording)) }
        let(:list) { attached_list.list }
        let(:params) { { recording_id: attached_list.model_id } }

        it { expect(response).to be_successful }
      end

      context 'when given session_id param' do
        let(:attached_list) { create(:attached_list) }
        let(:list) { attached_list.list }
        let(:params) { { session_id: attached_list.model_id } }

        it { expect(response).to be_successful }
      end

      context 'when given order, order_by, limit and offset params' do
        let(:params) do
          {
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
      before do
        get :show, params: { id: list.id }, format: :json
      end

      it { expect(response).to be_successful }
    end

    describe 'POST create:' do
      let(:params) do
        {
          name: Forgery(:lorem_ipsum).words(3, random: true),
          description: Forgery(:lorem_ipsum).words(15, random: true),
          selected: [true, false].sample,
          url: "https://#{Forgery(:internet).domain_name}/"
        }
      end

      before do
        post :create, params: params, format: :json
      end

      it { expect(response).to be_successful }
    end

    describe 'PUT update:' do
      let(:params) do
        {
          id: list.id,
          name: Forgery(:lorem_ipsum).words(3, random: true),
          description: Forgery(:lorem_ipsum).words(15, random: true),
          selected: [true, false].sample,
          url: "https://#{Forgery(:internet).domain_name}/"
        }
      end

      before do
        put :update, params: params, format: :json
      end

      it { expect(response).to be_successful }
    end

    describe 'DELETE destroy:' do
      before do
        delete :destroy, params: { id: list.id }, format: :json
      end

      it { expect(response).to be_successful }
    end
  end
end
