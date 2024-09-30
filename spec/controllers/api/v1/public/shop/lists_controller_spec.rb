# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::Shop::ListsController do
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

      context 'when given recording_id param' do
        let(:attached_list) { create(:attached_list, model: create(:recording)) }
        let(:list) { attached_list.list }
        let(:params) { { model_id: attached_list.model_id, model_type: 'Recording' } }

        it { expect(response).to be_successful }
      end

      context 'when given video_id param' do
        let(:attached_list) { create(:attached_list, model: create(:video)) }
        let(:list) { attached_list.list }
        let(:params) { { model_id: attached_list.model_id, model_type: 'Video' } }

        it { expect(response).to be_successful }
      end

      context 'when given session_id param' do
        let(:attached_list) { create(:attached_list, model: create(:session)) }
        let(:list) { attached_list.list }
        let(:params) { { model_id: attached_list.model_id, model_type: 'Session' } }

        it { expect(response).to be_successful }
      end

      context 'when given channel_id param' do
        let(:attached_list) { create(:attached_list, model: create(:channel)) }
        let(:list) { attached_list.list }
        let(:params) { { model_id: attached_list.model_id, model_type: 'Channel' } }

        it { expect(response).to be_successful }
      end

      context 'when given order, order_by, limit and offset params' do
        let(:attached_list) { create(:attached_list) }
        let(:params) do
          {
            model_id: attached_list.model_id,
            model_type: attached_list.model_type,
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
  end
end
