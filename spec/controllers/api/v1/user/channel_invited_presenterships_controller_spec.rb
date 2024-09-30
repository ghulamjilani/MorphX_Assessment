# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ChannelInvitedPresentershipsController do
  let(:current_user) { presentership.presenter.user }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }
  let(:presentership) { create(:channel_invited_presentership_pending) }

  render_views

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
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given channel_id, status params' do
        let(:params) do
          {
            status: 'pending',
            channel_id: presentership.channel_id
          }
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given limit, offset, order and order_by params' do
        let(:params) do
          {
            limit: 1,
            offset: 1,
            order: 'asc',
            order_by: 'status'
          }
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET show:' do
      before do
        get :show, params: { id: presentership.id }, format: :json
      end

      it { expect(response).to be_successful }
      it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
    end

    describe 'PUT update:' do
      before do
        put :update, params: params, format: :json
      end

      context 'when given status accepted' do
        let(:params) do
          {
            id: presentership.id,
            status: 'accepted'
          }
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given status rejected' do
        let(:params) do
          {
            id: presentership.id,
            status: 'accepted'
          }
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
