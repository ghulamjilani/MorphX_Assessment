# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::ChannelSubscriptionPlansController do
  let(:channel) { create(:listed_channel) }
  let(:subscription) { create(:subscription, channel: channel) }
  let!(:plans) { create_list(:stripe_db_plan, 4, channel_subscription: subscription) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when channel exsits' do
        before { get :index, params: { channel_id: channel.id }, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET show:' do
      context 'when plan exsits' do
        before { get :show, params: { channel_id: channel.id, id: plans.first.id }, format: :json }

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
