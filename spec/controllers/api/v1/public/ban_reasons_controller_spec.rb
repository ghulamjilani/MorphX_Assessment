# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::BanReasonsController do
  let(:ban_reason) { create(:ban_reason) }

  describe '.json request format' do
    describe 'GET index:' do
      it 'responds with 200 and returns valid json' do
        ban_reason
        get :index, params: {}, format: :json
        expect(response).to be_successful
      end
    end

    describe 'GET show:' do
      it 'responds with 200 and returns valid json' do
        get :show, params: { id: ban_reason.id }, format: :json
        expect(response).to be_successful
      end
    end
  end
end
